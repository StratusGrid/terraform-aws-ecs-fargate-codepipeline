### This uploads the task definition and appspec as a zip

resource "aws_s3_bucket_object" "artifacts_s3" {
  for_each = var.ecs_services

  bucket = var.ecs_services[each.key].codepipeline_source_bucket_id
  key    = var.ecs_services[each.key].codepipeline_source_object_key
  source = data.archive_file.artifacts[each.key].output_path
  etag   = filemd5(data.archive_file.artifacts[each.key].output_path)
}

data "archive_file" "artifacts" {
  for_each = var.ecs_services

  type        = "zip"
  output_path = "${path.module}/dist/${each.key}-artifacts.zip"

  source {
    filename = "taskdef.json"
    content  = <<EOF
{
  "family": "${var.ecs_services[each.key].taskdef_family}",
  "cpu": "${var.ecs_services[each.key].taskdef_cpu}",
  "memory": "${var.ecs_services[each.key].taskdef_memory}",
  "executionRoleArn": "${var.ecs_services[each.key].taskdef_execution_role_arn}",
  "taskRoleArn": "${var.ecs_services[each.key].taskdef_task_role_arn}",
  "compatibilities": [
    "EC2",
    "FARGATE"
  ],
  "requiresCompatibilities": ${jsonencode(var.ecs_services[each.key].taskdef_requires_compatibilities)},
  "networkMode": "${var.ecs_services[each.key].taskdef_network_mode}",
  "containerDefinitions": ${var.ecs_services[each.key].codepipeline_container_definitions}
}
EOF
  }

  source {
    filename = "appspec.yaml"
    content  = <<EOF
version: 0.0 
Resources: 
  - TargetService: 
      Type: AWS::ECS::Service 
      Properties: 
        TaskDefinition: <TASK_DEFINITION> 
        LoadBalancerInfo: 
          ContainerName: "${var.ecs_services[each.key].lb_container_name}" 
          ContainerPort: "${var.ecs_services[each.key].lb_container_port}" 
        PlatformVersion: "${var.ecs_services[each.key].platform_version}"
EOF

  }
}
