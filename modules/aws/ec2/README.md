# AWS EC2 Module

Terraform module to launch a single EC2 instance with optional Elastic IP, additional EBS volumes, and encrypted root storage.

## Features

- Automatic AMI lookup (latest Amazon Linux 2023) when no `ami_id` is provided
- Encrypted root EBS volume by default
- Optional additional EBS volumes (attached and tagged automatically)
- Optional Elastic IP allocation
- Detailed CloudWatch monitoring toggle
- EC2 termination protection toggle

## Usage

### Minimal

```hcl
module "ec2" {
  source = "github.com/huynguyen260398/dep-tf-modules//modules/aws/ec2?ref=v1.0.0"

  name      = "bastion"
  subnet_id = "subnet-0abc123"
}
```

### With EIP and Extra Volume

```hcl
module "ec2" {
  source = "github.com/huynguyen260398/dep-tf-modules//modules/aws/ec2?ref=v1.0.0"

  name                   = "app-server"
  instance_type          = "t3.medium"
  subnet_id              = "subnet-0abc123"
  vpc_security_group_ids = ["sg-0abc123"]

  create_eip            = true
  root_volume_size      = 30
  root_volume_encrypted = true
  monitoring            = true

  additional_ebs_volumes = [
    {
      device_name = "/dev/sdf"
      size        = 100
      type        = "gp3"
      encrypted   = true
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name prefix for all resources | `string` | — | yes |
| `subnet_id` | Subnet to launch the instance in | `string` | — | yes |
| `ami_id` | AMI ID. Defaults to latest Amazon Linux 2023 | `string` | `""` | no |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `vpc_security_group_ids` | Security group IDs | `list(string)` | `[]` | no |
| `key_name` | EC2 key pair name | `string` | `""` | no |
| `iam_instance_profile` | IAM instance profile name | `string` | `""` | no |
| `user_data` | Base64-encoded user data | `string` | `""` | no |
| `root_volume_size` | Root EBS volume size (GiB, min 8) | `number` | `20` | no |
| `root_volume_type` | Root EBS volume type | `string` | `"gp3"` | no |
| `root_volume_encrypted` | Encrypt the root volume | `bool` | `true` | no |
| `associate_public_ip_address` | Associate a public IP | `bool` | `false` | no |
| `disable_api_termination` | Enable termination protection | `bool` | `false` | no |
| `monitoring` | Enable detailed CloudWatch monitoring | `bool` | `false` | no |
| `create_eip` | Allocate and attach an Elastic IP | `bool` | `false` | no |
| `additional_ebs_volumes` | Additional EBS volumes to attach | `list(object)` | `[]` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `instance_arn` | EC2 instance ARN |
| `private_ip` | Private IP address |
| `public_ip` | Public IP (EIP if created, otherwise instance public IP) |
| `private_dns` | Private DNS hostname |
| `availability_zone` | AZ the instance was launched in |
| `ami_id` | AMI ID used |
| `eip_allocation_id` | Elastic IP allocation ID (null if not created) |
| `additional_ebs_volume_ids` | IDs of additional EBS volumes |
