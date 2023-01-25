terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

provider "aws" {
  access_key = var.key
  secret_key = var.key
  region     = var.region

  # only required for non-virtual hosted-style endpoint use case.
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_force_path_style
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = var.localstack_url
    cloudformation = var.localstack_url
    cloudwatch     = var.localstack_url
    dynamodb       = var.localstack_url
    ec2            = var.localstack_url
    es             = var.localstack_url
    elasticache    = var.localstack_url
    firehose       = var.localstack_url
    iam            = var.localstack_url
    kinesis        = var.localstack_url
    lambda         = var.localstack_url
    rds            = var.localstack_url
    redshift       = var.localstack_url
    route53        = var.localstack_url
    s3             = var.localstack_s3_url
    secretsmanager = var.localstack_url
    ses            = var.localstack_url
    sns            = var.localstack_url
    sqs            = var.localstack_url
    ssm            = var.localstack_url
    stepfunctions  = var.localstack_url
    sts            = var.localstack_url
  }

  default_tags {
    tags = {
      Environment = "dev"
      Service     = "localstack"
    }
  }
}
