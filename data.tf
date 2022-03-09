data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}
