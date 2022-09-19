#tflint-ignore: terraform_unused_declarations  -- Ignores warning about unused resources
data "aws_caller_identity" "current" {}

#tflint-ignore: terraform_unused_declarations  -- Ignores warning about unused resources
data "aws_region" "current" {}