variable "name" {
  description = "Name prefix for all resources created by this module."
  type        = string
}

variable "ami_id" {
  description = "ID of the AMI to use for the instance. If empty, the latest Amazon Linux 2023 AMI is used."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "ID of the subnet to launch the instance in."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the instance."
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Name of the EC2 key pair to attach to the instance. Leave empty to attach no key pair."
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "Name of an existing IAM instance profile to attach. Leave empty to skip."
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Base64-encoded user data script to run on first boot."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root volume size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  description = "EBS volume type for the root device (gp3, gp2, io1, io2)."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "root_volume_type must be one of: gp2, gp3, io1, io2."
  }
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root EBS volume."
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Enable EC2 Instance Termination Protection."
  type        = bool
  default     = false
}

variable "monitoring" {
  description = "Enable detailed CloudWatch monitoring for the instance."
  type        = bool
  default     = false
}

variable "create_eip" {
  description = "Whether to allocate and associate an Elastic IP with the instance."
  type        = bool
  default     = false
}

variable "additional_ebs_volumes" {
  description = "List of additional EBS volumes to attach to the instance."
  type = list(object({
    device_name = string
    size        = number
    type        = optional(string, "gp3")
    encrypted   = optional(bool, true)
  }))
  default = []
}

variable "tags" {
  description = "Map of additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
