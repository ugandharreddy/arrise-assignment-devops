terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  all_instances = { for inst in var.instances : inst.name => inst }

  protected_instances = {
    for name, inst in local.all_instances : name => inst
    if name == var.protected_instance_name
  }

  normal_instances = {
    for name, inst in local.all_instances : name => inst
    if name != var.protected_instance_name
  }
}

resource "aws_instance" "protected" {
  for_each = local.protected_instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    delete_on_termination = true
    iops                  = contains(["io1", "io2"], each.value.root_volume_type) ? each.value.iops : null
  }

  tags = merge(
    {
      Name        = each.value.name
      Environment = each.value.environment
      Owner       = each.value.owner
    },
    each.value.tags
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "standard" {
  for_each = local.normal_instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    delete_on_termination = true
    iops                  = contains(["io1", "io2"], each.value.root_volume_type) ? each.value.iops : null
  }

  tags = merge(
    {
      Name        = each.value.name
      Environment = each.value.environment
      Owner       = each.value.owner
    },
    each.value.tags
  )
}
