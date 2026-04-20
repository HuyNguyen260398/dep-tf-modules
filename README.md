# dep-tf-modules

A library of reusable, production-ready Terraform modules for AWS services. Each module is self-contained, independently versioned, and designed for composition across environments.

## Available Modules

| Module | Description |
|--------|-------------|
| [aws/ec2](modules/aws/ec2) | Launch EC2 instances with optional EIP, additional EBS volumes, and encrypted root storage |

## Usage

Reference a module directly from this repository:

```hcl
module "ec2" {
  source = "github.com/huynguyen260398/dep-tf-modules//modules/aws/ec2?ref=v1.0.0"

  name                   = "web-server"
  instance_type          = "t3.small"
  subnet_id              = "subnet-0abc123"
  vpc_security_group_ids = ["sg-0abc123"]

  root_volume_size      = 30
  root_volume_encrypted = true
  monitoring            = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

> [!NOTE]
> Always pin to a specific `ref` (tag or commit SHA) in production to avoid unexpected changes from upstream updates.

## Module Structure

Every module follows this layout:

```
modules/aws/<service>/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables with validation
├── outputs.tf       # Exported attributes
├── versions.tf      # Provider version constraints
├── README.md        # Module-specific documentation
├── examples/
│   └── complete/    # Runnable end-to-end example
└── tests/
    └── *_test.go    # Terratest integration tests
```

## Requirements

| Tool | Minimum Version |
|------|----------------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| Go (for tests) | >= 1.21 |

## Running Tests

Tests use [Terratest](https://terratest.gruntwork.io/) and deploy real infrastructure — ensure valid AWS credentials are configured before running.

```bash
cd modules/aws/ec2/tests
go test -v -timeout 30m
```

> [!WARNING]
> Tests create and destroy real AWS resources. You will incur charges during the test run.

## Development

```bash
# Validate a module
terraform -chdir=modules/aws/ec2 validate

# Format all HCL files
terraform fmt -recursive

# Run the complete example
terraform -chdir=modules/aws/ec2/examples/complete init
terraform -chdir=modules/aws/ec2/examples/complete plan
```
