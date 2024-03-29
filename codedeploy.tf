resource "aws_codedeploy_app" "this" {
  for_each = var.ecs_services

  compute_platform = "ECS"
  name             = var.ecs_services[each.key].service_name
}

resource "aws_codedeploy_deployment_group" "this" {
  for_each = var.ecs_services

  app_name               = aws_codedeploy_app.this[each.key].name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = var.ecs_services[each.key].service_name
  service_role_arn       = var.ecs_services[each.key].codedeploy_role_arn

  auto_rollback_configuration {
    enabled = var.ecs_services[each.key].codebuild_auto_rollback_enabled
    events  = var.ecs_services[each.key].codebuild_auto_rollback_events
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.ecs_services[each.key].codedeploy_termination_wait_time
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.this[each.key].name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.ecs_services[each.key].lb_listener_prod_arn]
      }
      test_traffic_route {
        listener_arns = [var.ecs_services[each.key].lb_listener_test_arn]
      }

      target_group {
        name = var.ecs_services[each.key].lb_target_group_blue_name
      }

      target_group {
        name = var.ecs_services[each.key].lb_target_group_green_name
      }
    }
  }
}
