output "secret_manager_iam_arn" {
  value = aws_iam_role.irsa.arn
}
