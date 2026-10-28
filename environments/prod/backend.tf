terraform {
  backend "s3" {
    bucket         = "arrise-terraform-state-bucket"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "arrise-terraform-locks"
  }
}