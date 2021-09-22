<!-- BEGIN_TF_DOCS -->
# ecs-fargate-codepipeline

ecs-fargate-codepipeline creates an end to end fargate cluster with a single task (but can be multiple containers in the task), a CodeDeploy application deployment configuration, a CodePipeline to wrap around it, and all relevant iam roles etc.

### NOTE:

If you get a Cycle: Error: on destroy, go remove the LB target group that is getting changes first.
```shell
terraform apply -target aws_lb_target_group.data_hub_web_http
```

If you get errors about the artifact.zip files, you must create the resources which get pulled into the file first, by targeting the iam roles and target groups.

```shell
terraform apply -target aws_lb_target group.<blue_target_group> -target aws_lb_target_group.<green_target_group>
terraform apply -target module.<ecs_iam_role1> -target module.<ecs_iam_role2>
```

### Example Usage:
Create a cluster with a single service, mapped to a single task, which has a single container:
```hcl
module "ecs_app_iam_role" {
  source  = "StratusGrid/ecs-iam-role-builder/aws"
  version = "~> 1.0"
  # source  = "github.com/GenesisFunction/terraform-aws-ecs-iam-role-builder"
  # source = "./modules/ecs-iam-role-builder"

  cloudwatch_logs_policy     = true
  cloudwatch_logs_group_path = module.ecs_fargate_app.log_group_path

  ecr_policy = true
  ecr_repos  = [
    aws_ecr_repository.app.arn
  ]

  custom_policy_jsons = [data.aws_iam_policy_document.bucket_access.json, data.aws_iam_policy_document.ssm_parameters.json]
  
  role_name  = "${var.name_prefix}-app${local.name_suffix}"
  input_tags = merge(local.common_tags, {})
}


resource "aws_service_discovery_private_dns_namespace" "discovery_namespace" {
  name        = "discovery.${var.env_name}.mydomain.com"
  description = "My services ${var.env_name} discovery namespace"
  vpc         = data.aws_vpc.vpc_microservices.id

  tags = merge(local.common_tags, {})
}

resource "aws_service_discovery_service" "discovery_service" {
  name = "myapp"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.common_tags, {})
}


# valid combinations of cpu/memory in task definition: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
module "ecs_fargate_app" {
  source  = "StratusGrid/ecs-fargate-codepipeline/aws"
  version = "~> 0.1"
  # source  = "github.com/StratusGrid/terraform-aws-ecs-fargate-codepipeline"

  ecs_cluster_name   = "${var.name_prefix}-app${local.name_suffix}"
  log_retention_days = 30
  vpc_id             = data.aws_vpc.vpc_microservices.id

  input_tags = merge(local.common_tags, {})

  task_definitions = [
    {
      # task definition configs
      task_name   = "app"
      task_cpu    = 256
      task_memory = 512

      execution_role_arn = module.ecs_app_iam_role.iam_role_arn
      
      # service configs
      platform_version = "1.3.0"
      desired_count    = 1
      security_groups  = [aws_security_group.admin.id]
      subnets          = data.aws_subnet_ids.public_subnets
      assign_public_ip = true
      propagate_tags   = "TASK_DEFINITION"
      log_group_path   = local.sso_service_log_group_a
      enable_execute_command = false

      service_registries = { // only accepts a single block
        registry_arn = aws_service_discovery_service.discovery_service.arn
      }

      # load balancer configs
      health_check_grace_period_seconds = 10
      
      lb_target_group_arn = aws_lb_target_group.data_hub_web_http_api.arn
      lb_container_name   = "app"
      lb_container_port   = 3001
      
      # container configs in task definition
      container_definitions = <<DEFINITION
[
  {
    "name": "app",
    "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/app-dev:latest",
    "essential": true,
    "cpu": 256,
    "memory": 512,
    "memoryReservation": 512,
    "secrets": [
      {"name": "pgdatabase","valueFrom": "${aws_ssm_parameter.data_hub_pgdatabase.arn}"},
      {"name": "pguser","valueFrom": "${aws_ssm_parameter.data_hub_pguser.arn}"},
      {"name": "pgpassword","valueFrom": "${aws_ssm_parameter.data_hub_pgpassword.arn}"},
    ],
    "environment": [],
    "portMappings": [
      {
        "containerPort": 3001,
        "hostPort": 3001
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${module.ecs_fargate_app.log_group_path}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
        }
    }
  }
]
DEFINITION
    }
  ]
}
```

---

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codedeploy_app.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codepipeline.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket_object.artifacts_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_codebuild_container_duplicator_name"></a> [codebuild\_container\_duplicator\_name](#input\_codebuild\_container\_duplicator\_name) | Optional variable to be provided when you are pushing containers to another repo after a successful code pipeline | `string` | `""` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | name to be used for ecs cluster and base log group | `string` | n/a | yes |
| <a name="input_ecs_services"></a> [ecs\_services](#input\_ecs\_services) | List of Maps containing all settings which are configured per task definition. | <pre>map(object(<br>    {<br>      service_name           = string<br>      platform_version       = string<br>      desired_count          = number<br>      security_groups        = list(string)<br>      subnets                = list(string)<br>      assign_public_ip       = bool<br>      propagate_tags         = string<br>      log_group_path         = string<br>      enable_execute_command = bool<br><br>      service_registries = map(string)<br><br>      health_check_grace_period_seconds = number<br><br>      lb_listener_prod_arn       = string<br>      lb_listener_test_arn       = string<br>      lb_target_group_blue_arn   = string<br>      lb_target_group_blue_name  = string<br>      lb_target_group_green_name = string<br>      lb_container_name          = string<br>      lb_container_port          = number<br><br>      codedeploy_role_arn              = string<br>      codedeploy_termination_wait_time = number<br>      codebuild_auto_rollback_enabled  = bool<br>      codebuild_auto_rollback_events   = list(string)<br><br>      codedepipeline_role_arn        = string<br>      codepipeline_source_bucket_id  = string<br>      codepipeline_source_object_key = string<br><br>      container_repo_name         = string<br>      container_target_tag        = string<br>      container_duplicate_targets = map(any) #This must have values for target_repo and target_account or an empty map<br>      deployment_manual_approval  = list(string)<br>      duplication_manual_approval = list(string)<br><br>      taskdef_family                   = string<br>      taskdef_execution_role_arn       = string<br>      taskdef_task_role_arn            = string<br>      taskdef_network_mode             = string<br>      taskdef_requires_compatibilities = list(string)<br>      taskdef_cpu                      = number<br>      taskdef_memory                   = number<br><br>      taskdef_container_definitions      = string<br>      codepipeline_container_definitions = string<br><br>      postdeploy_codebuild_project_name = list(string)<br><br>      # task_definition = string<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | name of environment/stage, passed in from root module | `string` | n/a | yes |
| <a name="input_input_tags"></a> [input\_tags](#input\_input\_tags) | Map of tags to apply to resources | `map(string)` | <pre>{<br>  "Developer": "StratusGrid",<br>  "Provisioner": "Terraform"<br>}</pre> | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs for. Configured on Log Group which all log streams are put under. | `number` | n/a | yes |
| <a name="input_termination_wait_time"></a> [termination\_wait\_time](#input\_termination\_wait\_time) | Termination wait time for blue green deployments | `number` | `5` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC which all resources will be put into | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codedeploy_app_arns_map"></a> [codedeploy\_app\_arns\_map](#output\_codedeploy\_app\_arns\_map) | Map of ARNs of CodeDeploy app created by this module. |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of ECS cluster created by this module. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | ARN of ECS cluster created by this module. |

---

## Contributors
- Chris Hurst [StratusChris](https://github.com/StratusChris)
- Ivan Casco [ivancasco-sg](https://github.com/ivancasco-sg)
- Jason Drouhard [jason-drouhard](https://github.com/jason-drouhard)
- Matt Barlow [mattbarlow-sg](https://github.com/mattbarlow-sg)
- Jonathan Woods [stratusgrid-jw](https://github.com/stratusgrid-jw)
- Angel Lopez [angellopez-sg](https://github.com/angellopez-sg)

Note, manual changes to the README will be overwritten when the documentation is updated. To update the documentation, run `terraform-docs -c .config/.terraform-docs.yml .`
<!-- END_TF_DOCS -->
