provider "aws" {
  region = "us-east-1"
}

module "cross_account_iam" {
  source = "../../modules/cross_account_iam"

  account_mode = "b"
  account_id_a = "000000000000"
  account_id_b = "111111111111"
  bucket_name  = "arrise-cross-account-demo-bucket"
}

output "role_c_arn" {
  value = module.cross_account_iam.role_c_arn
}
