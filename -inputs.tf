variable "input_tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {
    Developer   = "StratusGrid"
    Provisioner = "Terraform"
  }
}

variable "cicd_account_number" {
  description = "12-digit AWS account number for the account which calls the CodeDeploy Deployment Group. This can be used to allow the CodeDeploy to be triggered from another account. String type for use in IAM policy."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to deploy the service to"
  type        = string
}

variable "service_name" {
  description = "Name of ECS Service"
  type        = string
}

variable "platform_version" {
  description = "ECS platform version to use"
  type        = string
  default     = "1.4.0"
}

variable "desired_count" {
  description = "Number of tasks to run before autoscaling changes"
  type        = number
  default     = 2
}

variable "security_groups" {
  description = "Security groups to attach to task network interfaces"
  type        = list(string)
}

variable "subnets" {
  description = "Subnets to attach task network interfaces to"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Boolean to indicate whether to assign public IPs to task network interfaces"
  type        = bool
  default     = false
}

variable "propagate_tags" {
  description = "Setting to determine where to replicate tags to"
  type        = string
  default     = "TASK_DEFINITION"
}

variable "log_group_path" {
  description = "Cloudwatch log group path"
  type        = string
}

variable "enable_execute_command" {
  description = "Enable ecs container exec for container cli access"
  type        = bool
  default     = true
}

variable "service_registries" {
  description = "Service discovery registries to attach to the service. AWS currently only supports a single registry."
  type        = map(string)
  default     = {}
}

variable "use_custom_capacity_provider_strategy" {
  description = "Boolean to enable a custom capacity provider strategy for the ecs service. This would be used to utilize Fargate Spot for instance."
  type        = bool
  default     = false
}

variable "custom_capacity_provider_strategy" {
  description = "Map to define the custom capacity provider strategy for the service. This would be used to utilize Fargate Spot for instance."
  type        = map(string)
  default     = {}
}

variable "health_check_grace_period_seconds" {
  description = "Number of seconds before a failing healthcheck on a new ecs task will kill the task"
  type        = number
  default     = 60
}

variable "lb_listener_prod_arn" {
  description = "CodeDeploy group production traffic listener"
  type        = string
}

variable "lb_listener_test_arn" {
  description = "CodeDeploy group test traffic listener"
  type        = string
}

variable "lb_target_group_blue_arn" {
  description = "ARN of target group to be used as blue in CodeDeploy deployment style"
  type        = string
}

variable "lb_target_group_blue_name" {
  description = "Name of target group to be used as blue in CodeDeploy deployment style"
  type        = string
}

variable "lb_target_group_green_name" {
  description = "ARN of target group to be used as green in CodeDeploy deployment style"
  type        = string
}

variable "lb_container_name" {
  description = "Name of container in the task's container definition which is attached to the load balancer"
  type        = string
}

variable "lb_container_port" {
  description = "Exposed container port, must match the task's container definition and will be attached to the load balancer"
  type        = number
}

variable "codedeploy_role_additional_policies" {
  description = "Map of additional policies to attach to the CodeDeploy role. Should be formatted as {key = arn}"
  type        = map(string)
  default     = {}
}

variable "codedeploy_termination_wait_time" {
  description = "Wait time in seconds for CodeDeploy to wait before terminating previous production tasks after redirecting traffic to the new tasks"
  type        = number
  default     = 300
}

variable "codedeploy_auto_rollback_enabled" {
  description = "Boolean to determine whether CodeDeploy should automatically roll back when a rollback event is triggered"
  type        = bool
  default     = true
}

variable "codedeploy_auto_rollback_events" {
  description = "CodeDeploy rollback events which will trigger an automatic rollback"
  type        = list(string)
  default = [
    "DEPLOYMENT_FAILURE",
    "DEPLOYMENT_STOP_ON_ALARM",
    "DEPLOYMENT_STOP_ON_REQUEST"
  ]
}

variable "codepipeline_source_bucket_id" {
  description = "S3 bucket where the output artifact zip should be placed (appspec and task definition) to be pulled into pipeline as a source. Must be reachable by principal applying TF and the CodeDeploy Group role."
  type        = string
}

variable "codepipeline_source_object_key" {
  description = "Key for zip file inside of S3 bucket whhich CodePipeline pulls in as a source stage.  Must be reachable by principal applying TF and the CodeDeploy Group role."
  type        = string
}

variable "taskdef_family" {
  description = "Task Definition name which is then versioned. Should match the service name."
  type        = string
}

variable "taskdef_execution_role_arn" {
  description = "Execution role for ECS to use when provisioning the tasks. Used for things like pulling ecr images, emitting logs, getting secrets to inject, etc."
  type        = string
}

variable "taskdef_task_role_arn" {
  description = "Role attached to ECS tasks to give them access to resources"
  type        = string
}

variable "taskdef_network_mode" {
  description = "Network mode for task network interfaces, should always be awsvpc for Fargate"
  type        = string
  default     = "awsvpc"
}

variable "taskdef_requires_compatibilities" {
  description = "ECS compatibilities to help determine task placement"
  type        = list(string)
  default = [
    "FARGATE"
  ]
}

variable "taskdef_cpu" {
  description = "CPU units to allocate to the task"
  type        = number
}

variable "taskdef_memory" {
  description = "MB of memory to allocate to the task"
  type        = number
}

variable "log_retention_days" {
  description = "Number of days CloudWatch Log Group should retain logs from this service for"
  type        = number
  default     = 30
}

variable "initialization_container_definitions" {
  description = "This is the placeholder container definition that the cluster will be provisioned with. It does not need to be working and will be replaced on the first CodeDeploy execution."
  type        = string
}

variable "codepipeline_container_definitions" {
  description = "This is the template container definition which CodePipeline will interpolate and deploy the service with CodeDeploy."
  type        = string
}