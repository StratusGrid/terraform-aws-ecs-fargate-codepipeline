variable "env_name" {
  description = "name of environment/stage, passed in from root module"
  type        = string
}

variable "ecs_cluster_name" {
  description = "name to be used for ecs cluster and base log group"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs for. Configured on Log Group which all log streams are put under."
  type        = number
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

variable "termination_wait_time" {
  description = "Deprecated. Use codedeploy_termination_wait_time in the ecs_services object instead."
  type        = number
  default     = 5
}

variable "codebuild_container_duplicator_name" {
  description = "Optional variable to be provided when you are pushing containers to another repo after a successful code pipeline"
  type        = string
  default     = ""
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
      codebuild_auto_rollback_enabled  = bool
      codebuild_auto_rollback_events   = list(string)

      codedepipeline_role_arn        = string
      codepipeline_source_bucket_id  = string
      codepipeline_source_object_key = string

      container_repo_name         = string
      container_target_tag        = string
      container_duplicate_targets = map(any) #This must have values for target_repo and target_account or an empty map
      deployment_manual_approval  = list(string)
      duplication_manual_approval = list(string)

      taskdef_family                   = string
      taskdef_execution_role_arn       = string
      taskdef_task_role_arn            = string
      taskdef_network_mode             = string
      taskdef_requires_compatibilities = list(string)
      taskdef_cpu                      = number
      taskdef_memory                   = number

      taskdef_container_definitions      = string
      codepipeline_container_definitions = string

      predeploy_codebuild_project_name  = list(string)
      postdeploy_codebuild_project_name = list(string)

      # task_definition = string
    }
  ))
}
