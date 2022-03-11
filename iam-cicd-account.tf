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