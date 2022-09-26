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

codebuild_container_duplicator_name = aws_codebuild_project.codebuild_container_duplicator.name

ecs_services = {
service_name = local.service_name

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

# example of the locals file
locals {
service_name = {
service_name           = "MyService"
platform_version       = "1.4.0"
desired_count          = 3
security_groups        = ["sg-02f8f5de8655a798f","sg-031232157553fbec9"]
subnets                = ["subnet-0735beb51e4293b3e","subnet-0fdc8f5dc6d101035"]
assign_public_ip       = false
propagate_tags         = "TASK_DEFINITION"
log_group_path         = "/ecs/cluster_name/service_name"
enable_execute_command = true

service_registries = {}

#NOTE: ALBs are not created by the module.
health_check_grace_period_seconds = 600
lb_listener_prod_arn              = "arn:aws:elasticloadbalancing:us-east-1:123456789876:listener/app/my_prd_listener/ed9abd4ebab2925a/9176f3bfebd6457f"
lb_listener_test_arn              = "arn:aws:elasticloadbalancing:us-east-1:123456789876:listener/app/my_test_listener/j6d77m8jttgd4g853/mqo39m4lcj3lfk3"
lb_target_group_blue_arn          = "arn:aws:elasticloadbalancing:us-east-1:123456789876:targetgroup/my_blue_target_group/f1fec68432dd54c0"
lb_target_group_blue_name         = my_blue_target_group
lb_target_group_green_name        = my_green_target_group
lb_container_name                 = "containername" # has to match name in container definition within task_definition
lb_container_port                 = 8080       # has to match port in container definition within task_definition

codedeploy_role_arn              = "arn:aws:iam::123456789876:role/my_codedeploy_role"
codedeploy_termination_wait_time = "5"
codebuild_auto_rollback_enabled  = true
codebuild_auto_rollback_events   = ["DEPLOYMENT_FAILURE"]

codepipeline_role_arn        = "arn:aws:iam::123456789876:role/my_codepipeline_role"
codepipeline_source_bucket_id  = "my_codepipeline_source_bucket_name"
codepipeline_source_object_key = "deployment/ecs/${var.application_name}-artifacts.zip"

container_repo_name         = "my_ecr_repository"
container_target_tag        = "latest" #
container_duplicate_targets = "${var.name_prefix}-${var.application_name}-ecr-repo-prd"

deployment_manual_approval  = local.ecs_deployment_approval[var.env_name] // boolean for environment to deploy into (prd)
duplication_manual_approval = local.ecs_duplication_approval[var.env_name] // boolen for environment to duplicate from (dev)

use_custom_capacity_provider_strategy = true //if false, custom_capacity_provider_strategy needs to be an emtpy block = {}
custom_capacity_provider_strategy = {
primary_capacity_provider_base      = 1
primary_capacity_provider           = "FARGATE"
primary_capacity_provider_weight    = 10
secondary_capacity_provider         = "FARGATE_SPOT"
secondary_capacity_provider_weight  = 1
}

taskdef_family             = "MyService"
taskdef_execution_role_arn = "arn:aws:iam::123456789876:role/my_taskdef_role"
taskdef_task_role_arn      = "arn:aws:iam::123456789876:role/my_taskdef_role"
taskdef_network_mode       = "awsvpc"
taskdef_requires_compatibilities = [
"FARGATE"
]
taskdef_cpu    = 2048
taskdef_memory = 4096

taskdef_container_definitions = <<-TASKDEF
[
{
"name": "containername",
"image": "IMAGE1_NAME",
"portMappings": [
{
"hostPort": 8080,
"protocol": "tcp",
"containerPort": 8080
}
]
}
]
TASKDEF

codepipeline_container_definitions = <<-CONTAINERDEF
[
{
"name": "containername",
"image": "<IMAGE1_NAME>",
"essential": true,
"logConfiguration": {
"logDriver": "awslogs",
"secretOptions": null,
"options": {
"awslogs-group": "log-group",
"awslogs-region": "us-east-1",
"awslogs-stream-prefix": "ecs"
}
},
"portMappings": [
{
"hostPort": 8080,
"protocol": "tcp",
"containerPort": 8080
}
],
"environment": [
{ "name": "ENVIRONMENT", "value": "${var.env_name == "prd" ? "production" : "development"}" }
]
}
]
CONTAINERDEF

postdeploy_codebuild_project_name = ["My_PostDeploy_Project"]

} # end of service definition
}
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
| <a name="input_ecs_services"></a> [ecs\_services](#input\_ecs\_services) | List of Maps containing all settings which are configured per task definition. | <pre>map(object(<br>    {<br>      service_name           = string<br>      platform_version       = string<br>      desired_count          = number<br>      security_groups        = list(string)<br>      subnets                = list(string)<br>      assign_public_ip       = bool<br>      propagate_tags         = string<br>      log_group_path         = string<br>      enable_execute_command = bool<br><br>      service_registries = map(string)<br><br>      use_custom_capacity_provider_strategy = bool<br>      custom_capacity_provider_strategy     = map(string)<br><br>      health_check_grace_period_seconds = number<br><br>      lb_listener_prod_arn       = string<br>      lb_listener_test_arn       = string<br>      lb_target_group_blue_arn   = string<br>      lb_target_group_blue_name  = string<br>      lb_target_group_green_name = string<br>      lb_container_name          = string<br>      lb_container_port          = number<br><br>      codedeploy_role_arn              = string<br>      codedeploy_termination_wait_time = number<br>      codebuild_auto_rollback_enabled  = bool<br>      codebuild_auto_rollback_events   = list(string)<br><br>      codedepipeline_role_arn        = string<br>      codepipeline_source_bucket_id  = string<br>      codepipeline_source_object_key = string<br><br>      container_repo_name         = string<br>      container_target_tag        = string<br>      container_duplicate_targets = map(any) #This must have values for target_repo and target_account or an empty map<br>      deployment_manual_approval  = list(string)<br>      duplication_manual_approval = list(string)<br><br>      taskdef_family                   = string<br>      taskdef_execution_role_arn       = string<br>      taskdef_task_role_arn            = string<br>      taskdef_network_mode             = string<br>      taskdef_requires_compatibilities = list(string)<br>      taskdef_cpu                      = number<br>      taskdef_memory                   = number<br><br>      taskdef_container_definitions      = string<br>      codepipeline_container_definitions = string<br><br>      predeploy_codebuild_project_name  = list(string)<br>      postdeploy_codebuild_project_name = list(string)<br><br>      # task_definition = string<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | name of environment/stage, passed in from root module | `string` | n/a | yes |
| <a name="input_input_tags"></a> [input\_tags](#input\_input\_tags) | Map of tags to apply to resources | `map(string)` | <pre>{<br>  "Developer": "StratusGrid",<br>  "Provisioner": "Terraform"<br>}</pre> | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs for. Configured on Log Group which all log streams are put under. | `number` | n/a | yes |
| <a name="input_termination_wait_time"></a> [termination\_wait\_time](#input\_termination\_wait\_time) | Deprecated. Use codedeploy\_termination\_wait\_time in the ecs\_services object instead. | `number` | `5` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC which all resources will be put into | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codedeploy_app_arns_map"></a> [codedeploy\_app\_arns\_map](#output\_codedeploy\_app\_arns\_map) | Map of ARNs of CodeDeploy app created by this module. |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of ECS cluster created by this module. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | ARN of ECS cluster created by this module. |

---

## Contributors
- Chris Hurst [GenesisChris](https://github.com/GenesisChris)
- Ivan Casco [ivancasco-sg](https://github.com/ivancasco-sg)
- Jason Drouhard [jason-drouhard](https://github.com/jason-drouhard)
- Matt Barlow [mattbarlow-sg](https://github.com/mattbarlow-sg)
- Jonathan Woods [stratusgrid-jw](https://github.com/stratusgrid-jw)
- Angel Lopez [angellopez-sg](https://github.com/angellopez-sg)

Note, manual changes to the README will be overwritten when the documentation is updated. To update the documentation, run `terraform-docs -c .config/.terraform-docs.yml .`
<!-- END_TF_DOCS -->