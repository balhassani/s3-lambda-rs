resource "aws_s3_bucket" "bucket" {
  bucket        = "dev"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_object" "file_upload" {
  for_each = fileset(path.module, "data/*.json")

  bucket = aws_s3_bucket.bucket.id
  key    = each.value
  source = "${path.module}/${each.value}"
}

resource "aws_iam_user" "new_user" {
  name = "new-user"
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "test policy"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.bucket.arn}"
    }
  ]
}
EOT
}

resource "aws_iam_user_policy_attachment" "attachment" {
  user       = aws_iam_user.new_user.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  filename      = "${path.module}/target/lambda/s3-lambda-rs/bootstrap.zip"
  function_name = "func"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.test"
  runtime       = "provided.al2"

  environment {
    variables = {
      RUST_BACKTRACE   = "1",
      BUCKET_NAME      = "dev",
      BOOTSTRAP_SERVER = "localhost:9092"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
