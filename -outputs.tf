output "ecs_cluster_arn" {
  description = "ARN of ECS cluster created by this module."
  value = aws_ecs_cluster.this.arn
}