data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "cicd_artifacts" {
  bucket = var.cicd_artifact_bucket_name
}

data "aws_kms_key" "cicd_encryption_key" {
  key_id = var.cicd_kms_encryption_key_arn
}