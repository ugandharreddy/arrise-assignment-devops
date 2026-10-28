output "group1_name" {
  value = length(aws_iam_group.group1) > 0 ? aws_iam_group.group1[0].name : null
}

output "group2_name" {
  value = length(aws_iam_group.group2) > 0 ? aws_iam_group.group2[0].name : null
}

output "role_c_arn" {
  value = length(aws_iam_role.roleC) > 0 ? aws_iam_role.roleC[0].arn : null
}
