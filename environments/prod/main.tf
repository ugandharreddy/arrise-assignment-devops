provider "aws" {
  region = var.region
}

module "ec2_cluster" {
  source = "../../modules/ec2_multi_instance"

  instances               = var.instances
  protected_instance_name = var.protected_instance_name
}

output "instance_ids" {
  value = module.ec2_cluster.instance_ids
}

output "instance_private_ips" {
  value = module.ec2_cluster.instance_private_ips
}
