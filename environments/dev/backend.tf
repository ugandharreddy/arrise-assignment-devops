terraform {
  backend "s3" {
    bucket      = "arrise-terraform-state-bucket"
    key         = "environments/dev/terraform.tfstate"
    region      = "us-east-1"
    encrypt     = true
    use_lockfile = true
  }
}