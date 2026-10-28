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
  account_a_resources = var.account_mode == "a"
  account_b_resources = var.account_mode == "b"
}

resource "aws_iam_group" "group1" {
  count = local.account_a_resources ? 1 : 0
  name  = "group1"
}

resource "aws_iam_group" "group2" {
  count = local.account_a_resources ? 1 : 0
  name  = "group2"
}

resource "aws_iam_user" "group1_members" {
  for_each = local.account_a_resources ? toset(var.group1_members) : toset([])
  name     = each.value
}

resource "aws_iam_user" "group2_members" {
  for_each = local.account_a_resources ? toset(var.group2_members) : toset([])
  name     = each.value
}

resource "aws_iam_group_membership" "group1_membership" {
  count = local.account_a_resources ? 1 : 0
  name  = "group1-membership"
  users = [for user in aws_iam_user.group1_members : user.name]
  group = aws_iam_group.group1[0].name
}

resource "aws_iam_group_membership" "group2_membership" {
  count = local.account_a_resources ? 1 : 0
  name  = "group2-membership"
  users = [for user in aws_iam_user.group2_members : user.name]
  group = aws_iam_group.group2[0].name
}

resource "aws_iam_user_policy" "ci_pipeline" {
  count = local.account_a_resources && contains(var.group1_members, "ci") ? 1 : 0
  user  = aws_iam_user.group1_members["ci"].name
  name  = "ci-pipeline-minimal-policy"
  policy = file("${path.module}/ci-policy.json")
}

resource "aws_iam_policy" "role_a_no_iam" {
  count = local.account_a_resources ? 1 : 0
  name  = "roleA-AdminExceptIAM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
        NotAction = [
          "iam:*",
          "organizations:*",
          "account:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "roleA" {
  count = local.account_a_resources ? 1 : 0
  name  = var.role_a_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.role_a_trusted_account}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "roleA_admin" {
  count      = local.account_a_resources ? 1 : 0
  role       = aws_iam_role.roleA[0].name
  policy_arn = aws_iam_policy.role_a_no_iam[0].arn
}

resource "aws_iam_role" "roleB" {
  count = local.account_a_resources ? 1 : 0
  name  = var.role_b_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.role_b_trusted_account}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "roleB_assume_account_b" {
  count = local.account_a_resources ? 1 : 0
  name  = "roleB-AssumeAccountB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::${var.account_id_b}:role/${var.role_c_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "roleB_assume_policy" {
  count      = local.account_a_resources ? 1 : 0
  role       = aws_iam_role.roleB[0].name
  policy_arn = aws_iam_policy.roleB_assume_account_b[0].arn
}

resource "aws_s3_bucket" "bucket" {
  count  = local.account_b_resources ? 1 : 0
  bucket = var.bucket_name
}

resource "aws_iam_role" "roleC" {
  count = local.account_b_resources ? 1 : 0
  name  = var.role_c_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id_a}:role/${var.role_b_name}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "bucket_full_access" {
  count = local.account_b_resources ? 1 : 0
  name  = "roleC-BucketFullAccess"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.bucket[0].arn
      },
      {
        Sid    = "AllowObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.bucket[0].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "roleC_bucket_policy" {
  count      = local.account_b_resources ? 1 : 0
  role       = aws_iam_role.roleC[0].name
  policy_arn = aws_iam_policy.bucket_full_access[0].arn
}
