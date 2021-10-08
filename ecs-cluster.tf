# cluster
resource "aws_ecs_cluster" "this" {
  name                = var.ecs_cluster_name
  tags                = merge(var.input_tags, {})
  capacity_providers  = ["FARGATE", "FARGATE_SPOT"]
}
