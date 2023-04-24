# # This is needed to import the taskdefinition json as a terraform map since aws_ecs_task_definition doesn't support json content
# data "null_data_source" "this" {
#   for_each = var.ecs_services

#   inputs = jsondecode(var.ecs_services[each.key].task_definition)
# }

resource "aws_ecs_task_definition" "this" {
  for_each = var.ecs_services

  family                   = var.ecs_services[each.key].taskdef_family
  execution_role_arn       = var.ecs_services[each.key].taskdef_execution_role_arn
  task_role_arn            = var.ecs_services[each.key].taskdef_task_role_arn
  network_mode             = var.ecs_services[each.key].taskdef_network_mode
  requires_compatibilities = var.ecs_services[each.key].taskdef_requires_compatibilities
  cpu                      = var.ecs_services[each.key].taskdef_cpu
  memory                   = var.ecs_services[each.key].taskdef_memory

  dynamic "volume" {
    for_each = var.ecs_services[each.key].efs_volume

    content {
      name = var.ecs_services[each.key].efs_volume.name
      efs_volume_configuration {
        file_system_id          = var.ecs_services[each.key].efs_volume.file_system_id
        root_directory          = var.ecs_services[each.key].efs_volume.root_directory
        transit_encryption      = var.ecs_services[each.key].efs_volume.transit_encryption
        transit_encryption_port = var.ecs_services[each.key].efs_volume.transit_encryption_port
      }
    }
  }

  tags = merge(var.input_tags, {})

  container_definitions = var.ecs_services[each.key].taskdef_container_definitions
}

#tflint-ignore: terraform_required_providers -- Ignore warning on version constraint
resource "aws_ecs_service" "this" {
  for_each = var.ecs_services

  name             = var.ecs_services[each.key].service_name
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this[each.key].arn
  desired_count    = var.ecs_services[each.key].desired_count
  launch_type      = var.ecs_services[each.key].use_custom_capacity_provider_strategy == true ? null : "FARGATE"
  platform_version = var.ecs_services[each.key].platform_version
  propagate_tags   = var.ecs_services[each.key].propagate_tags

  network_configuration {
    security_groups  = var.ecs_services[each.key].security_groups
    subnets          = var.ecs_services[each.key].subnets
    assign_public_ip = var.ecs_services[each.key].assign_public_ip
  }

  enable_execute_command = var.ecs_services[each.key].enable_execute_command

  dynamic "service_registries" {
    for_each = lookup(each.value, "service_registries", {})
    content {
      registry_arn = service_registries.value
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = lookup(each.value, "custom_capacity_provider_strategy", {})
    content {
      base              = lookup(var.ecs_services[each.key].custom_capacity_provider_strategy, "primary_capacity_provider_base")
      capacity_provider = lookup(var.ecs_services[each.key].custom_capacity_provider_strategy, "primary_capacity_provider")
      weight            = lookup(var.ecs_services[each.key].custom_capacity_provider_strategy, "primary_capacity_provider_weight")
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = lookup(each.value, "custom_capacity_provider_strategy", {})
    content {
      capacity_provider = lookup(var.ecs_services[each.key].custom_capacity_provider_strategy, "secondary_capacity_provider")
      weight            = lookup(var.ecs_services[each.key].custom_capacity_provider_strategy, "secondary_capacity_provider_weight")
    }
  }

  health_check_grace_period_seconds = var.ecs_services[each.key].health_check_grace_period_seconds
  #dynamic "load_balancer" {
  #  for_each = var.ecs_services[each.key].lb_toggle
  #  content {
  #    target_group_arn = var.ecs_services[each.key].lb_target_group_blue_arn
  #    container_name   = var.ecs_services[each.key].lb_container_name
  #    container_port   = var.ecs_services[each.key].lb_container_port 
  #  }
  #}
  load_balancer {
    target_group_arn = var.ecs_services[each.key].lb_target_group_blue_arn
    container_name   = var.ecs_services[each.key].lb_container_name
    container_port   = var.ecs_services[each.key].lb_container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  tags = merge(var.input_tags, {})

  #ignoring changes since codedeploy manages this after the initial deployment
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer
    ]
  }
}
