### This uploads the task definition and appspec as a zip

resource "aws_s3_bucket_object" "artifacts_s3" {

  bucket      = var.codepipeline_source_bucket_id
  key         = var.codepipeline_source_object_key
  source      = data.archive_file.artifacts.output_path
  source_hash = md5(jsonencode(data.archive_file.artifacts.source))
  acl         = "bucket-owner-full-control"
  kms_key_id  = var.codepipeline_source_bucket_kms_key_arn
}

locals {
  artifact_taskdef_file_name = "taskdef.json"
  artifact_appspec_file_name = "appspec.yaml"
}

data "archive_file" "artifacts" {

  type        = "zip"
  output_path = "${path.module}/dist/${var.service_name}-artifacts.zip"

  source {
    filename = local.artifact_taskdef_file_name
    content  = <<EOF
{
  "family": "${var.taskdef_family}",
  "cpu": "${var.taskdef_cpu}",
  "memory": "${var.taskdef_memory}",
  "executionRoleArn": "${var.taskdef_execution_role_arn}",
  "taskRoleArn": "${var.taskdef_task_role_arn}",
  "compatibilities": [
    "EC2",
    "FARGATE"
  ],
  "requiresCompatibilities": ${jsonencode(var.taskdef_requires_compatibilities)},
  "networkMode": "${var.taskdef_network_mode}",
  "containerDefinitions": ${var.codepipeline_container_definitions}
}
EOF
  }

  dynamic "source" {
    for_each = var.use_custom_capacity_provider_strategy == true ? [1] : []
    content {
      filename = local.artifact_appspec_file_name
      content  = <<-EOF
      version: 0.0
      Resources:
        - TargetService:
            Type: AWS::ECS::Service
            Properties:
              TaskDefinition: <TASK_DEFINITION>
              LoadBalancerInfo:
                ContainerName: "${var.lb_container_name}"
                ContainerPort: "${var.lb_container_port}"
              PlatformVersion: "${var.platform_version}"
              CapacityProviderStrategy:
                - Base: "${lookup(var.custom_capacity_provider_strategy, "primary_capacity_provider_base")}"
                  CapacityProvider: "${lookup(var.custom_capacity_provider_strategy, "primary_capacity_provider")}"
                  Weight: "${lookup(var.custom_capacity_provider_strategy, "primary_capacity_provider_weight")}"
                - CapacityProvider: "${lookup(var.custom_capacity_provider_strategy, "secondary_capacity_provider")}"
                  Weight: "${lookup(var.custom_capacity_provider_strategy, "secondary_capacity_provider_weight")}"
      EOF
    }
  }

  dynamic "source" {
    for_each = var.use_custom_capacity_provider_strategy == false ? [1] : []
    content {
      filename = local.artifact_appspec_file_name
      content  = <<-EOF
      version: 0.0
      Resources:
        - TargetService:
            Type: AWS::ECS::Service
            Properties:
              TaskDefinition: <TASK_DEFINITION>
              LoadBalancerInfo:
                ContainerName: "${var.lb_container_name}"
                ContainerPort: "${var.lb_container_port}"
              PlatformVersion: "${var.platform_version}"
      EOF
    }
  }

}
