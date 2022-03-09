output "ecs_cluster_name" {
  description = "ARN of ECS cluster created by this module."
  value       = var.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of ECS cluster created by this module."
  value       = aws_ecs_cluster.this.arn
}

output "codedeploy_app_arns_map" {
  description = "Map of ARNs of CodeDeploy app created by this module."
  value = tomap({
    for k, service in aws_codedeploy_app.this : k => service.arn
  })
}