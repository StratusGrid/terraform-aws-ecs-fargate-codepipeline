resource "aws_iam_role" "cicd_crossaccount_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS" = var.cicd_aws_pipeline_account_number
        }
      }
    ]
  })

  tags = merge(var.input_tags, {})
}

resource "aws_iam_role_policy_attachment" "managed_s3_read_only_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.cicd_crossaccount_role.name
}

data "aws_iam_policy_document" "cicd_crossaccount_codedeploy_access" {
  statement {
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cicd_crossaccount_codedeploy_policy" {
  policy = data.aws_iam_policy_document.cicd_crossaccount_codedeploy_access.json
  role   = aws_iam_role.cicd_crossaccount_role.id
}

#data "aws_iam_policy_document" "cicd_crossaccount_bucket_access" {
#  statement {
#    effect = "Allow"
#    actions = [
#      "s3:GetObject*",
#      "s3:PutObject",
#      "s3:PutObjectAcl",
#      "codecommit:ListBranches",
#      "codecommit:ListRepositories"
#    ]
#    resources = [data.aws_s3_bucket.cicd_artifacts.arn]
#  }
#}
