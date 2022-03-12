resource "aws_iam_role" "cicd_account_role" {
  name = "${var.service_name}-cicd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS" = formatlist("arn:aws:iam::%s:root", var.trusted_account_numbers)
        }
      }
    ]
  })

  tags = merge(var.input_tags, {})
}

data "aws_iam_policy_document" "cicd_account_codedeploy_access" {
  statement {
    sid    = "AllowCodeDeployGroupTriggers"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment"
    ]
    resources = [
      aws_codedeploy_deployment_group.this.arn,
      "${aws_codedeploy_deployment_group.this.arn}/*"
    ]
  }
  statement {
    sid    = "AllowCodeDeployAppTriggers"
    effect = "Allow"
    actions = [
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [aws_codedeploy_app.this.arn]
  }
  statement {
    sid    = "AllowECSRegistration"
    effect = "Allow"
    actions = [
      "codedeploy:GetDeploymentConfig",
      "ecs:RegisterTaskDefinition",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowToS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      "arn:aws:s3:::${var.codepipeline_source_bucket_id}/*"
    ]
  }
  statement {
    sid    = "AllowToKMS"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [var.codepipeline_source_bucket_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "cicd_account_codedeploy_policy" {
  policy = data.aws_iam_policy_document.cicd_account_codedeploy_access.json
  role   = aws_iam_role.cicd_account_role.id
}
