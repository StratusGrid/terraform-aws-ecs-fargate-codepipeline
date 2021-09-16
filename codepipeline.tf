resource "aws_codepipeline" "this" {
  for_each = var.ecs_services

  tags = var.input_tags

  name     = var.ecs_services[each.key].service_name
  role_arn = var.ecs_services[each.key].codedepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket_object.artifacts_s3[each.key].bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      owner            = "AWS"
      name             = "ArtifactsECR"
      category         = "Source"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["ArtifactsECR"]

      configuration = {
        RepositoryName = var.ecs_services[each.key].container_repo_name
        ImageTag       = var.ecs_services[each.key].container_target_tag
      }
    }

    action {
      owner            = "AWS"
      name             = "ArtifactsS3"
      category         = "Source"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["ArtifactsS3"]

      configuration = {
        PollForSourceChanges = "false"
        S3Bucket             = aws_s3_bucket_object.artifacts_s3[each.key].bucket #
        S3ObjectKey          = aws_s3_bucket_object.artifacts_s3[each.key].key
      }
    }
  }


  stage {
    name = "Deploy_to_${upper(var.env_name)}"

    dynamic "action" {
      for_each = var.ecs_services[each.key].deployment_manual_approval
      content {
        category         = "Approval"
        configuration    = {}
        input_artifacts  = []
        name             = "Deploy_Approval"
        output_artifacts = []
        owner            = "AWS"
        provider         = "Manual"
        run_order        = 1
        version          = "1"
      }
    }
    action {
      name            = "Deploy_to_${upper(var.env_name)}"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["ArtifactsECR", "ArtifactsS3"]
      version         = "1"
      run_order       = 2

      configuration = {
        AppSpecTemplateArtifact        = "ArtifactsS3"
        ApplicationName                = var.ecs_services[each.key].service_name
        DeploymentGroupName            = aws_codedeploy_deployment_group.this[each.key].deployment_group_name
        Image1ArtifactName             = "ArtifactsECR"
        Image1ContainerName            = "IMAGE1_NAME"
        TaskDefinitionTemplateArtifact = "ArtifactsS3"
        AppSpecTemplatePath            = "appspec.yaml"
        TaskDefinitionTemplatePath     = "taskdef.json"
      }
    }
    dynamic "action" {
      for_each = var.ecs_services[each.key].postdeploy_codebuild_project_name
      content {
        category          = "Build"
        name              = "PostDeploy_CodeBuild"
        owner             = "AWS"
        provider          = "CodeBuild"
        version           = "1"
        run_order         = 3
        input_artifacts   = ["ArtifactsECR"]
        output_artifacts  = []

        configuration = {
          ProjectName = join("", var.ecs_services[each.key].postdeploy_codebuild_project_name)
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.ecs_services[each.key].container_duplicate_targets

    content {
      name = "ContainerDuplication-${var.ecs_services[each.key].container_duplicate_targets.target.repo}"
      #name = "Push_container_to_${var.env_name}"

      dynamic "action" {
        for_each = var.ecs_services[each.key].duplication_manual_approval
        content {
          category         = "Approval"
          configuration    = {}
          input_artifacts  = []
          name             = "Duplication_Approval"
          output_artifacts = []
          owner            = "AWS"
          provider         = "Manual"
          run_order        = 1
          version          = "1"
        }
      }

      action {
        owner           = "AWS"
        name            = var.codebuild_container_duplicator_name
        category        = "Build"
        provider        = "CodeBuild"
        version         = "1"
        run_order       = 2
        input_artifacts = ["ArtifactsECR"]

        configuration = {
          EnvironmentVariables = jsonencode([ # this allows you to pass the target ecr repo to the codebuild
            {
              name  = "ECR_TARGET_REPO"
              value = var.ecs_services[each.key].container_duplicate_targets.target.repo
              type  = "PLAINTEXT"
            },
            {
              name  = "ECR_TARGET_ACCOUNT"
              value = var.ecs_services[each.key].container_duplicate_targets.target.account
              type  = "PLAINTEXT"
            }
          ])
          ProjectName = var.codebuild_container_duplicator_name
        }
      }
    }
  }
}



resource "aws_iam_role" "this" {
  for_each = var.ecs_services

  name = "${var.ecs_services[each.key].service_name}-event-trigger-role"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "this" {
  for_each = var.ecs_services

  name = "${var.ecs_services[each.key].service_name}-event-trigger-role"
  role = aws_iam_role.this[each.key].id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.this[each.key].arn}"
            ]
        }
    ]
}
DOC
}


resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.ecs_services

  name        = "codepipeline-trigger-${var.ecs_services[each.key].service_name}"
  description = "Event-based trigger that starts codepipeline for ${var.ecs_services[each.key].service_name}"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecr"
  ],
  "detail": {
    "eventName": [
      "PutImage"
    ],
    "requestParameters": {
      "repositoryName": [
        "${var.ecs_services[each.key].container_repo_name}"
      ],
      "imageTag": [
        "latest"
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = var.ecs_services

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = aws_codepipeline.this[each.key].name
  arn       = aws_codepipeline.this[each.key].arn
  role_arn  = aws_iam_role.this[each.key].arn
}
