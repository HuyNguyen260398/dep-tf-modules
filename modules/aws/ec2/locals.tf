locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id

  common_tags = merge(
    { Name = var.name },
    var.tags
  )
}
