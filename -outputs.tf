output "ecs_cluster_name" {
  description = "ARN of ECS cluster created by this module."
  value = aws_ecs_cluster.this.name
}

output "ecs_cluster_arn" {
  description = "ARN of ECS cluster created by this module."
  value = aws_ecs_cluster.this.arn
}