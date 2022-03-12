resource "aws_iam_role" "this_codedeploy" {
  name = var.service_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge(
    var.input_tags,
    {
    },
  )
}

resource "aws_iam_role_policy" "this_codedeploy" {
  name = var.service_name
  role = aws_iam_role.this_codedeploy.id

  policy = jsonencode(
    {
      "Version" = "2012-10-17"
      "Statement" = [
        {
          Action = [
            "ecs:DescribeServices",
            "ecs:CreateTaskSet",
            "ecs:UpdateServicePrimaryTaskSet",
            "ecs:DeleteTaskSet",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:ModifyRule",
            "lambda:InvokeFunction",
            "cloudwatch:DescribeAlarms",
            "sns:Publish"
          ],
          Resource = "*",
          Effect   = "Allow"
        },
        {
          Action = [
            "iam:PassRole"
          ],
          Effect   = "Allow",
          Resource = "*",
          Condition = {
            "StringLike" = {
              "iam:PassedToService" = [
                "ecs-tasks.amazonaws.com"
              ]
            }
          }
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_additional_policies" {
  for_each   = var.codedeploy_role_additional_policies
  policy_arn = each.value
  role       = aws_iam_role.this_codedeploy.id
}