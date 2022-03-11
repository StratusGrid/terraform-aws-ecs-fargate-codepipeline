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
