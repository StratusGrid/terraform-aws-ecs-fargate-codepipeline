variable "ecs_cluster_name" {
  description = "name to be used for ecs cluster and base log group"
  type        = string
}

variable "vpc_id" {
  description = "VPC which all resources will be put into"
  type        = string
}

variable "input_tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {
    Developer   = "StratusGrid"
    Provisioner = "Terraform"
  }
}

variable "ecs_services" {
  description = "List of Maps containing all settings which are configured per task definition."
  type = map(object(
    {
      service_name           = string
      platform_version       = string
      desired_count          = number
      security_groups        = list(string)
      subnets                = list(string)
      assign_public_ip       = bool
      propagate_tags         = string
      log_group_path         = string
      enable_execute_command = bool

      service_registries = map(string)

      use_custom_capacity_provider_strategy = bool
      custom_capacity_provider_strategy = map(string)

      health_check_grace_period_seconds = number

      lb_listener_prod_arn       = string
      lb_listener_test_arn       = string
      lb_target_group_blue_arn   = string
      lb_target_group_blue_name  = string
      lb_target_group_green_name = string
      lb_container_name          = string
      lb_container_port          = number

      codedeploy_role_arn              = string
      codedeploy_termination_wait_time = number
      codedeploy_auto_rollback_enabled  = bool
      codedeploy_auto_rollback_events   = list(string)

      codedepipeline_role_arn        = string
      codepipeline_source_bucket_id  = string
      codepipeline_source_object_key = string

      container_repo_name         = string

      taskdef_family                   = string
      taskdef_execution_role_arn       = string
      taskdef_task_role_arn            = string
      taskdef_network_mode             = string
      taskdef_requires_compatibilities = list(string)
      taskdef_cpu                      = number
      taskdef_memory                   = number
      log_retention_days               = number

      initialization_container_definitions = string
      codepipeline_container_definitions   = string

    }
  ))
}
