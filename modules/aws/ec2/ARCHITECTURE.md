# EC2 Module — Architecture Reference

## File Overview

| File | Role |
|------|------|
| `versions.tf` | Compatibility contract — declares required Terraform and provider versions |
| `variables.tf` | Public API — all inputs a caller can pass to the module |
| `locals.tf` | Internal computed values — derived from variables, not exposed to callers |
| `main.tf` | Infrastructure — all data sources and resources |
| `outputs.tf` | Exported attributes — values exposed to callers or parent modules |

---

## `versions.tf`

Declares the minimum tooling required to use this module.

- `required_version >= 1.5.0` — enforces a minimum Terraform CLI version. Required because `optional()` in object variable types (used in `variables.tf`) was introduced in Terraform 1.3.
- `aws ~> 5.0` — pins the AWS provider to the `5.x` major line. Allows minor/patch upgrades but blocks `6.0`, preventing silent breaking changes on `terraform init`.

---

## `variables.tf`

The interface between the module and its callers. Every argument a caller can configure is declared here.

### Required variables (no default)

| Variable | Type | Purpose |
|----------|------|---------|
| `name` | `string` | Name prefix applied to all resources |
| `subnet_id` | `string` | Subnet to launch the instance in |

### Optional variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `ami_id` | `""` | Custom AMI. When empty, latest Amazon Linux 2023 is resolved automatically |
| `instance_type` | `"t3.micro"` | EC2 hardware profile |
| `vpc_security_group_ids` | `[]` | Security groups controlling instance traffic |
| `key_name` | `""` | SSH key pair name. Empty = no key attached |
| `iam_instance_profile` | `""` | IAM role for the instance. Empty = no role attached |
| `user_data` | `""` | Base64-encoded bootstrap script |
| `root_volume_size` | `20` | Root EBS size in GiB (min 8) |
| `root_volume_type` | `"gp3"` | Root EBS type (`gp2`, `gp3`, `io1`, `io2`) |
| `root_volume_encrypted` | `true` | Encrypt the root volume |
| `associate_public_ip_address` | `false` | Assign an ephemeral public IP |
| `disable_api_termination` | `false` | Termination protection |
| `monitoring` | `false` | Detailed CloudWatch monitoring (1-min intervals) |
| `create_eip` | `false` | Allocate and attach a static Elastic IP |
| `additional_ebs_volumes` | `[]` | List of extra EBS volumes to create and attach |
| `tags` | `{}` | Additional tags applied to all resources |

### Validation blocks

Two variables enforce allowed values at plan time, before any AWS API call:

- `root_volume_size` — must be `>= 8` GiB (AWS minimum).
- `root_volume_type` — must be one of `gp2`, `gp3`, `io1`, `io2`.

---

## `locals.tf`

Internal derived values consumed by `main.tf`. Not accessible to callers.

```hcl
locals {
  ami_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id
  common_tags = merge({ Name = var.name }, var.tags)
}
```

- **`ami_id`** — resolves which AMI to use. If the caller provided one, use it directly; otherwise use the ID returned by the data source. Centralising this logic keeps the `aws_instance` resource block clean.
- **`common_tags`** — merges a mandatory `Name` tag with the caller's custom tags. Guarantees every resource gets a `Name` even when `var.tags` is empty, while still allowing callers to add their own keys.

---

## `main.tf`

Contains all data sources and resources. Five blocks in total.

### Block 1 — `data "aws_ami" "amazon_linux_2023"`

Queries the AWS AMI catalogue to find the latest Amazon Linux 2023 image.

- `count = var.ami_id == "" ? 1 : 0` — skipped entirely when the caller provides their own AMI, avoiding an unnecessary API call.
- `most_recent = true` — selects the newest match when multiple AMIs satisfy the filters.
- `owners = ["amazon"]` — restricts results to official AWS-published AMIs only.
- `filter name` — matches the Amazon Linux 2023 x86_64 naming pattern.
- `filter virtualization-type = hvm` — excludes older paravirtual AMIs incompatible with modern instance types.

The result is accessed as `data.aws_ami.amazon_linux_2023[0].id`. The `[0]` index is required because `count` always produces a list.

---

### Block 2 — `resource "aws_instance" "aws_ec2"`

The core EC2 instance resource.

**Placement**

| Argument | Notes |
|----------|-------|
| `ami` | From `local.ami_id` — caller-supplied or auto-resolved |
| `instance_type` | Hardware profile (CPU/RAM) |
| `subnet_id` | Determines AZ and public/private placement |
| `vpc_security_group_ids` | Firewall rules for the instance |

**Optional arguments**

`key_name`, `iam_instance_profile`, and `user_data_base64` are converted to `null` when their corresponding variables are empty strings. Terraform treats `null` as "omit this argument", which is cleaner than passing empty strings to the AWS API.

| Argument | Purpose |
|----------|---------|
| `key_name` | SSH key pair for instance access |
| `iam_instance_profile` | Grants the instance an IAM role for AWS API access without storing credentials |
| `user_data_base64` | Bootstrap script executed once on first boot |
| `associate_public_ip_address` | Assigns an ephemeral public IP (defaults to `false`) |
| `disable_api_termination` | Prevents accidental termination via API or console |
| `monitoring` | Enables 1-minute CloudWatch metrics (vs default 5-minute) |

**`root_block_device` sub-block**

Configures the boot disk inline. Root volumes cannot be managed as a separate `aws_ebs_volume` resource — they must be declared here.

- `delete_on_termination = true` — hardcoded so the root volume is automatically deleted when the instance is destroyed, preventing orphaned volumes.

**`tags` and `volume_tags`**

Both set to `local.common_tags`. `volume_tags` ensures the root EBS volume inherits the same tags as the instance — without it, the root volume is created untagged.

**`lifecycle` sub-block**

```hcl
lifecycle {
  ignore_changes = [ami_id, user_data_base64]
}
```

Tells Terraform to stop tracking drift on these two arguments after initial creation:

- `ami_id` — AWS regularly publishes new Amazon Linux 2023 AMIs. Without this, every `terraform plan` would propose replacing (destroying and recreating) the instance.
- `user_data_base64` — user data can only be changed by replacing the instance. Ignoring it prevents accidental replacements from minor script edits.

---

### Block 3 — `resource "aws_eip" "this"`

An Elastic IP is a **static** public IP that persists independently of the instance lifecycle. Without one, stopping and starting an instance assigns a different public IP each time.

- `count = var.create_eip ? 1 : 0` — only created when the caller opts in. When disabled, no EIP is allocated and no cost is incurred.
- `instance = aws_instance.aws_ec2.id` — associates the EIP with the instance and creates an implicit dependency, ensuring the instance is created first.
- `domain = "vpc"` — required for all modern EIPs used within a VPC.

---

### Block 4 — `resource "aws_ebs_volume" "additional"`

Creates one independent EBS volume per entry in `var.additional_ebs_volumes`.

- `count = length(var.additional_ebs_volumes)` — zero volumes by default; grows with the input list.
- `availability_zone = aws_instance.aws_ec2.availability_zone` — EBS volumes must be in the same AZ as their instance. Reading it from the instance avoids a caller misconfiguration and creates an implicit dependency.
- `count.index` — the loop index used to read the corresponding object from the input list.
- `tags = merge(local.common_tags, { Name = "..." })` — each volume gets a unique `Name` tag based on its device name while inheriting all other common tags.

---

### Block 5 — `resource "aws_volume_attachment" "additional"`

An EBS volume and an EC2 instance are separate AWS resources — creating them does not connect them. This resource is the explicit attachment relationship.

- `count` — mirrors block 4 exactly. Both counts must always match.
- `device_name` — the Linux device path the OS sees (e.g. `/dev/sdf`). Must be unique per instance.
- `volume_id` / `instance_id` — reference the corresponding volume and instance, which Terraform uses to build the dependency graph and enforce creation order.

---

## `outputs.tf`

Exposes instance attributes to callers for display (`terraform output`) or module composition (referencing `module.ec2.<output>` in a parent module).

| Output | Source | Notes |
|--------|--------|-------|
| `instance_id` | `aws_instance.aws_ec2.id` | Primary identifier for the instance |
| `instance_arn` | `aws_instance.aws_ec2.arn` | Used in IAM policies and cross-account references |
| `private_ip` | `aws_instance.aws_ec2.private_ip` | Always available regardless of public IP settings |
| `public_ip` | Conditional | Returns EIP address if `create_eip = true`, otherwise the instance's ephemeral public IP |
| `private_dns` | `aws_instance.aws_ec2.private_dns` | Internal DNS hostname for VPC-internal connectivity |
| `availability_zone` | `aws_instance.aws_ec2.availability_zone` | Useful for placing dependent resources in the same AZ |
| `ami_id` | `aws_instance.aws_ec2.ami` | Records which AMI was actually used |
| `eip_allocation_id` | `aws_eip.aws_eip[0].allocation_id` | `null` when no EIP was created |
| `additional_ebs_volume_ids` | `aws_ebs_volume.additional[*].id` | Empty list when no extra volumes were created |

The `public_ip` output demonstrates output-level conditional logic — callers get one consistent output name regardless of whether an EIP or an ephemeral IP is in use.

---

## Dependency Graph

Terraform resolves resource creation order automatically from the references in the code. No explicit `depends_on` is needed.

```
data.aws_ami  ──► local.ami_id
                       │
                       ▼
               aws_instance.aws_ec2
                │              │
                ▼              ▼
          aws_eip.aws_eip    aws_ebs_volume.additional
                                    │
                                    ▼
                          aws_volume_attachment.additional
```

---

## `resource` vs `module`

### `resource` — a single infrastructure object

A `resource` block tells Terraform to create, manage, and destroy **one specific thing** in a cloud provider. It maps directly to a single provider API call.

```hcl
resource "aws_instance" "aws_ec2" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}
```

The syntax is always `resource "<provider_type>" "<local_name>"`. There is no abstraction layer — what you write is exactly what gets created.

### `module` — a reusable group of resources

A `module` block calls a **packaged collection** of resources. It accepts inputs and returns outputs, hiding the internal implementation from the caller.

```hcl
module "ec2" {
  source        = "./modules/aws/ec2"
  name          = "web-server"
  subnet_id     = "subnet-0abc123"
  instance_type = "t3.small"
}
```

### Why this module uses `resource` internally

This directory **is** the module being packaged. Inside a module definition you always use `resource` blocks — that is the only way to provision infrastructure. The `module` keyword is used by a **caller** to invoke the package from the outside.

```
caller (uses "module" block)
    └── modules/aws/ec2/ (uses "resource" blocks internally)
            ├── resource "aws_instance" "aws_ec2"
            ├── resource "aws_eip" "aws_ec2"
            └── resource "aws_ebs_volume" "additional"
```

### When to use each

**Use `resource` directly when:**

- Authoring a module (as done here)
- The infrastructure is simple, one-off, and not intended to be reused

```hcl
# A quick S3 bucket for a specific project
resource "aws_s3_bucket" "assets" {
  bucket = "my-project-assets"
}
```

**Use `module` when:**

- Reusing a proven pattern across multiple environments or projects
- Enforcing organisational standards (tagging, encryption, naming) without every team having to repeat them
- Composing larger infrastructure from smaller building blocks

```hcl
# Three EC2 instances, all sharing the same module defaults
module "bastion" {
  source        = "../../modules/aws/ec2"
  name          = "bastion"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]
}

module "app_server" {
  source        = "../../modules/aws/ec2"
  name          = "app"
  instance_type = "t3.medium"
  subnet_id     = module.vpc.private_subnet_ids[0]
  monitoring    = true
}

module "worker" {
  source        = "../../modules/aws/ec2"
  name          = "worker"
  instance_type = "c6i.large"
  subnet_id     = module.vpc.private_subnet_ids[1]
}
```

### Summary

| | `resource` | `module` |
|--|-----------|---------|
| **What it does** | Creates one cloud object | Calls a packaged group of resources |
| **Used by** | Module authors | Module consumers |
| **Abstraction** | None — direct API mapping | Hides implementation details |
| **Reusability** | Low — copy-paste to reuse | High — parameterised and shareable |
| **Analogy** | A single function | A library you import and call |
