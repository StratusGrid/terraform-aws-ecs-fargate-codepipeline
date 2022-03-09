resource "aws_cloudwatch_log_group" "this" {
  for_each = var.ecs_services

  name = var.ecs_services[each.key].log_group_path #NOTE - If you change this, update outputs also

  retention_in_days = var.ecs_services[each.key].log_retention_days

  tags = merge(var.input_tags, {})
}

