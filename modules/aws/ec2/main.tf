data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name != "" ? var.key_name : null
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  user_data_base64            = var.user_data != "" ? var.user_data : null
  associate_public_ip_address = var.associate_public_ip_address
  disable_api_termination     = var.disable_api_termination
  monitoring                  = var.monitoring

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = var.root_volume_encrypted
    delete_on_termination = true
  }

  tags        = local.common_tags
  volume_tags = local.common_tags

  lifecycle {
    ignore_changes = [ami_id, user_data_base64]
  }
}

resource "aws_eip" "this" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = local.common_tags
}

resource "aws_ebs_volume" "additional" {
  count             = length(var.additional_ebs_volumes)
  availability_zone = aws_instance.this.availability_zone
  size              = var.additional_ebs_volumes[count.index].size
  type              = var.additional_ebs_volumes[count.index].type
  encrypted         = var.additional_ebs_volumes[count.index].encrypted

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.additional_ebs_volumes[count.index].device_name}"
  })
}

resource "aws_volume_attachment" "additional" {
  count       = length(var.additional_ebs_volumes)
  device_name = var.additional_ebs_volumes[count.index].device_name
  volume_id   = aws_ebs_volume.additional[count.index].id
  instance_id = aws_instance.this.id
}
