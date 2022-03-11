resource "aws_iam_role" "cicd_account_role" {
  name = "${var.service_name}-cicd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::${var.cicd_account_number}:root"
        }
      }
    ]
  })

  tags = merge(var.input_tags, {})
}

data "aws_iam_policy_document" "cicd_account_codedeploy_access" {
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

resource "aws_iam_role_policy" "cicd_account_codedeploy_policy" {
  policy = data.aws_iam_policy_document.cicd_account_codedeploy_access.json
  role   = aws_iam_role.cicd_account_role.id
}
