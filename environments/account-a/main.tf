provider "aws" {
  region = "us-east-1"
}

module "cross_account_iam" {
  source = "../../modules/cross_account_iam"

  account_mode = "a"
  account_id_a = "000000000000"
  account_id_b = "111111111111"
  bucket_name  = "arrise-cross-account-demo-bucket"

  group1_members = ["engine", "ci"]
  group2_members = ["ops-admin", "platform-admin"]
}

output "group1_name" {
  value = module.cross_account_iam.group1_name
}

output "group2_name" {
  value = module.cross_account_iam.group2_name
}
