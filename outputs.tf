output "upload-results" {
  value = fileset(path.module, "data/*.json")
}

output "iam-role-arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "bucket-arn" {
  value = aws_s3_bucket.bucket.arn
}