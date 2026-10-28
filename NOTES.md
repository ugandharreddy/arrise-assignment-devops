# Terraform EC2 Multi-Instance Notes

## Lifecycle protection

The lifecycle protection is intentionally applied to the instance named `app-03` in each environment. This instance is designated as the most critical workload in the fleet, so the `prevent_destroy` setting is enabled to stop accidental deletion during routine infrastructure updates or refactoring.

This protects the most important host from destructive changes while allowing the rest of the EC2 fleet to be updated more flexibly.

## Remote state and locking

With local state, if two engineers run `terraform apply` at the same time against the same environment, each one will read and write to a separate local state file. That creates a race condition: one apply can overwrite or partially conflict with the other, resulting in drift, failed changes, or an inconsistent infrastructure state.

The S3 backend stores the state remotely in an S3 bucket, and the DynamoDB table acts as a lock mechanism. When one person starts an apply, Terraform acquires the lock. If another person tries to run apply at the same time, Terraform must wait for the lock to be released before proceeding. This prevents simultaneous state writes and keeps the environment consistent.

## Multi-account IAM and cross-account access

1. Would I give `engine` and `ci` IAM users with access keys in a real production setup?

   In a real production environment, I would avoid long-lived access keys for human-operated tasks where possible. I would prefer federated identity via AWS IAM Identity Center / SSO, workload identity, or short-lived credentials from an identity provider. Access keys are useful for automation and CI systems, but for human accounts I would usually use console access or temporary role-based credentials instead of static keys. For `engine` and `ci`, I would normally place them behind an identity federation or least-privilege role-based flow rather than handing out static access keys unless there is a strict automation requirement.

2. Why does it matter whether roleC trusts the whole Account A root or only `roleB`'s specific ARN?

   Trusting the whole Account A root is broader and allows any principal from that account to assume roleC if the account has the right permissions and the trust policy allows it. Trusting only `arn:aws:iam::000000000000:role/roleB` narrows the trust to a single role, which reduces blast radius and prevents other principals in Account A from assuming the role. This is the least-privilege pattern and prevents unintended cross-account access.

## Custom CI policy

The CI user (`ci`) is given a custom inline policy, not a broad managed policy. The policy is scoped to the exact needs of the pipeline:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EcrPush",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "arn:aws:ecr:us-east-1:000000000000:repository/my-app"
    },
    {
      "Sid": "EcsDeploy",
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition"
      ],
      "Resource": [
        "arn:aws:ecs:us-east-1:000000000000:service/my-cluster/my-service",
        "arn:aws:ecs:us-east-1:000000000000:task-definition/my-app:*"
      ]
    },
    {
      "Sid": "ReadArtifactsBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::build-artifacts-bucket",
        "arn:aws:s3:::build-artifacts-bucket/*"
      ]
    }
  ]
}
```

What I deliberately left out and why:

- No `iam:*` access, because the pipeline should not create or modify roles or users.
- No broad `ecr:*` read/write across all repositories, because the CI job only needs a single repository.
- No `ecs:*` access for all clusters and services, because it should only update one named service.
- No `s3:PutObject`, `DeleteObject`, or bucket-wide write access for the artifact bucket, because build artifacts are read-only for the pipeline.
- No admin or PowerUser-style permissions, because those would allow the pipeline to change unrelated infrastructure and violate least privilege.
- No `sts:AssumeRole` for arbitrary accounts or roles, because the pipeline does not need to assume other identities beyond the explicit deployment context.

This keeps the CI identity limited to push, deploy, and read-only artifact access only.

## Bug fix for the broken cross-account trust setup

The broken snippet was failing for two separate reasons.

First, the trust policy was wrong because it trusted a user ARN instead of a role ARN. `roleB` is a role, not a user. In AWS, `sts:AssumeRole` trusts principals such as an IAM role or another account root, not an IAM user identity. The correct principal is `arn:aws:iam::000000000000:role/roleB` (or a specific account root only if the design intentionally allows all principals in that account). Because the original trust policy used `arn:aws:iam::000000000000:user/roleB`, Terraform created an invalid trust relationship and the role could not be assumed by the intended principal.

Second, the permissions policy was too broad and mis-scoped. `s3:*` with `Resource = "*"` grants full access to every S3 bucket in the account, which is far beyond the requirement. The access should instead be limited to the single named bucket and the specific object paths needed. In other words, the role was allowed to do everything in S3 instead of just the required bucket access. The correct approach is to grant only the minimal read/write actions the workload actually needs, and only on the target bucket ARN and object ARN.

The corrected pattern is:

```hcl
data "aws_iam_policy_document" "roleC_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::000000000000:role/roleB"]
    }
  }
}

resource "aws_iam_role" "roleC" {
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

resource "aws_iam_role_policy" "roleC_s3" {
  name = "roleC-s3-access"
  role = aws_iam_role.roleC.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::example-bucket",
          "arn:aws:s3:::example-bucket/*"
        ]
      }
    ]
  })
}
```

This fixes both problems: it trusts the correct principal for cross-account role assumption, and it scopes S3 access to only the required bucket and actions instead of allowing unrestricted S3 access.

## Execution steps

Use the environment directories that match the assignment requirements:

1. EC2 multi-instance environment
   - Open [environments/dev/main.tf](environments/dev/main.tf) and [environments/prod/main.tf](environments/prod/main.tf)
   - Run `terraform init -reconfigure`
   - Run `terraform plan`
   - Run `terraform apply`
   - The module at [modules/ec2_multi_instance/main.tf](modules/ec2_multi_instance/main.tf) drives all 5 EC2 instances from a single variable list and outputs the instance ID and private IP maps.

2. Remote state and locking
   - Each environment already contains the S3 backend configuration in [environments/dev/backend.tf](environments/dev/backend.tf) and [environments/prod/backend.tf](environments/prod/backend.tf)
   - The backend uses an S3 state bucket and DynamoDB lock table to avoid simultaneous writes
   - Run `terraform init -reconfigure` in each environment to connect to the remote backend

3. Cross-account IAM setup
   - Use [environments/account-a/main.tf](environments/account-a/main.tf) for Account A resources
   - Use [environments/account-b/main.tf](environments/account-b/main.tf) for Account B resources
   - Run `terraform init -reconfigure` and then `terraform plan` / `terraform apply` in each directory separately

4. CI least-privilege policy
   - The custom inline policy is stored in [modules/cross_account_iam/ci-policy.json](modules/cross_account_iam/ci-policy.json)
   - It is attached to the `ci` user in the Account A module configuration at [modules/cross_account_iam/main.tf](modules/cross_account_iam/main.tf)

5. Bug-fix validation
   - The trust policy and S3 policy bug fix are documented in this notes file and should be implemented in the cross-account role setup before apply

> No separate bootstrap folder is required for this assignment. The required backend is configured directly inside each environment, and the assignment does not require a standalone bootstrap stack.
