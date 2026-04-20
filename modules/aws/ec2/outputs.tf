output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance (empty if no public IP or EIP)."
  value       = var.create_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "private_dns" {
  description = "Private DNS name of the instance."
  value       = aws_instance.this.private_dns
}

output "availability_zone" {
  description = "Availability zone the instance was launched in."
  value       = aws_instance.this.availability_zone
}

output "ami_id" {
  description = "AMI ID used for the instance."
  value       = aws_instance.this.ami
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP (empty if not created)."
  value       = var.create_eip ? aws_eip.this[0].allocation_id : null
}

output "additional_ebs_volume_ids" {
  description = "IDs of any additional EBS volumes attached to the instance."
  value       = aws_ebs_volume.additional[*].id
}
