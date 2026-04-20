output "instance_id" {
  description = "EC2 instance ID."
  value       = module.ec2.instance_id
}

output "private_ip" {
  description = "Private IP of the instance."
  value       = module.ec2.private_ip
}

output "ami_id" {
  description = "AMI used by the instance."
  value       = module.ec2.ami_id
}
