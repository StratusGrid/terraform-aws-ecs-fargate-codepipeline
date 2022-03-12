<!-- BEGIN_TF_DOCS -->
# ecs-fargate-service

ecs-fargate-service is used to create an ecs service and the corresponding codedeploy, log groups, codepipeline artifacts,
etc. It is intended to be used with StratusGrid's multi-account ecs pipeline module to allow for container images to be
passed immutably from cluster to cluster in different environments and accounts in a single contiguous pipeline.

For this purpose, ecs-fargate-service outputs a map which can be used to provide configuration for an environment stage
when provisioning the pipeline.

## Examples
Example Outputs which can feed CodePipeline Module:
```terraform
codepipeline_variables = {
  "artifact_appspec_file_name" = "appspec.yaml"
  "artifact_bucket" = "my-bucket-name"
  "artifact_key" = "deployment/ecs/my-service-artifacts.zip"
  "artifact_kms_key_arn" = "arn:aws:kms:us-east-1:335895905019:key/5fc4e28f-44f1-6f00-b3e8-142fbd61390c"
  "artifact_taskdef_file_name" = "taskdef.json"
  "aws_account_number" = "123456789012"
  "codedeploy_deployment_app_arn" = "arn:aws:codedeploy:us-east-1:123456789012:application:my-service-name"
  "codedeploy_deployment_app_name" = "my-service-name"
  "codedeploy_deployment_group_arn" = "arn:aws:codedeploy:us-east-1:123456789012:deploymentgroup:my-service-name/my-service-name"
  "codedeploy_deployment_group_name" = "my-service-name"
  "trusting_account_role" = "arn:aws:iam::123456789012:role/my-service-name-cicd"
}
```

---

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codedeploy_app.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.cicd_account_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this_codedeploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cicd_account_codedeploy_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.this_codedeploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.codedeploy_role_additional_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket_object.artifacts_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Boolean to indicate whether to assign public IPs to task network interfaces | `bool` | `false` | no |
| <a name="input_codedeploy_auto_rollback_enabled"></a> [codedeploy\_auto\_rollback\_enabled](#input\_codedeploy\_auto\_rollback\_enabled) | Boolean to determine whether CodeDeploy should automatically roll back when a rollback event is triggered | `bool` | `true` | no |
| <a name="input_codedeploy_auto_rollback_events"></a> [codedeploy\_auto\_rollback\_events](#input\_codedeploy\_auto\_rollback\_events) | CodeDeploy rollback events which will trigger an automatic rollback | `list(string)` | <pre>[<br>  "DEPLOYMENT_FAILURE",<br>  "DEPLOYMENT_STOP_ON_ALARM",<br>  "DEPLOYMENT_STOP_ON_REQUEST"<br>]</pre> | no |
| <a name="input_codedeploy_role_additional_policies"></a> [codedeploy\_role\_additional\_policies](#input\_codedeploy\_role\_additional\_policies) | Map of additional policies to attach to the CodeDeploy role. Should be formatted as {key = arn} | `map(string)` | `{}` | no |
| <a name="input_codedeploy_termination_wait_time"></a> [codedeploy\_termination\_wait\_time](#input\_codedeploy\_termination\_wait\_time) | Wait time in seconds for CodeDeploy to wait before terminating previous production tasks after redirecting traffic to the new tasks | `number` | `300` | no |
| <a name="input_codepipeline_container_definitions"></a> [codepipeline\_container\_definitions](#input\_codepipeline\_container\_definitions) | This is the template container definition which CodePipeline will interpolate and deploy the service with CodeDeploy. | `string` | n/a | yes |
| <a name="input_codepipeline_source_bucket_id"></a> [codepipeline\_source\_bucket\_id](#input\_codepipeline\_source\_bucket\_id) | S3 bucket where the output artifact zip should be placed (appspec and task definition) to be pulled into pipeline as a source. Must be reachable by principal applying TF and the CodeDeploy Group role. | `string` | n/a | yes |
| <a name="input_codepipeline_source_bucket_kms_key_arn"></a> [codepipeline\_source\_bucket\_kms\_key\_arn](#input\_codepipeline\_source\_bucket\_kms\_key\_arn) | ARN of the KMS key used to encrypt objects in the bucket used to store and retrieve artifacts for the codepipeline. This KMS key should be the same for all services which are deployed from a single contiguous CodePipeline because CodePipeline needs a single KMS key to use for all artifacts across all Actions. If referencing the aws\_kms\_key resource, use the arn attribute. If referencing the aws\_kms\_alias data source or resource, use the target\_key\_arn attribute. | `string` | n/a | yes |
| <a name="input_codepipeline_source_object_key"></a> [codepipeline\_source\_object\_key](#input\_codepipeline\_source\_object\_key) | Key for zip file inside of S3 bucket whhich CodePipeline pulls in as a source stage.  Must be reachable by principal applying TF and the CodeDeploy Group role. | `string` | n/a | yes |
| <a name="input_custom_capacity_provider_strategy"></a> [custom\_capacity\_provider\_strategy](#input\_custom\_capacity\_provider\_strategy) | Map to define the custom capacity provider strategy for the service. This would be used to utilize Fargate Spot for instance. | `map(string)` | `{}` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of tasks to run before autoscaling changes | `number` | `2` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the ECS cluster to deploy the service to | `string` | n/a | yes |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Enable ecs container exec for container cli access | `bool` | `true` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Number of seconds before a failing healthcheck on a new ecs task will kill the task | `number` | `60` | no |
| <a name="input_initialization_container_definitions"></a> [initialization\_container\_definitions](#input\_initialization\_container\_definitions) | This is the placeholder container definition that the cluster will be provisioned with. It does not need to be working and will be replaced on the first CodeDeploy execution. | `string` | n/a | yes |
| <a name="input_input_tags"></a> [input\_tags](#input\_input\_tags) | Map of tags to apply to resources | `map(string)` | <pre>{<br>  "Developer": "StratusGrid",<br>  "Provisioner": "Terraform"<br>}</pre> | no |
| <a name="input_lb_container_name"></a> [lb\_container\_name](#input\_lb\_container\_name) | Name of container in the task's container definition which is attached to the load balancer | `string` | n/a | yes |
| <a name="input_lb_container_port"></a> [lb\_container\_port](#input\_lb\_container\_port) | Exposed container port, must match the task's container definition and will be attached to the load balancer | `number` | n/a | yes |
| <a name="input_lb_listener_prod_arn"></a> [lb\_listener\_prod\_arn](#input\_lb\_listener\_prod\_arn) | CodeDeploy group production traffic listener | `string` | n/a | yes |
| <a name="input_lb_listener_test_arn"></a> [lb\_listener\_test\_arn](#input\_lb\_listener\_test\_arn) | CodeDeploy group test traffic listener | `string` | n/a | yes |
| <a name="input_lb_target_group_blue_arn"></a> [lb\_target\_group\_blue\_arn](#input\_lb\_target\_group\_blue\_arn) | ARN of target group to be used as blue in CodeDeploy deployment style | `string` | n/a | yes |
| <a name="input_lb_target_group_blue_name"></a> [lb\_target\_group\_blue\_name](#input\_lb\_target\_group\_blue\_name) | Name of target group to be used as blue in CodeDeploy deployment style | `string` | n/a | yes |
| <a name="input_lb_target_group_green_name"></a> [lb\_target\_group\_green\_name](#input\_lb\_target\_group\_green\_name) | ARN of target group to be used as green in CodeDeploy deployment style | `string` | n/a | yes |
| <a name="input_log_group_path"></a> [log\_group\_path](#input\_log\_group\_path) | Cloudwatch log group path | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days CloudWatch Log Group should retain logs from this service for | `number` | `30` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | ECS platform version to use | `string` | `"1.4.0"` | no |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | Setting to determine where to replicate tags to | `string` | `"TASK_DEFINITION"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Security groups to attach to task network interfaces | `list(string)` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Name of ECS Service | `string` | n/a | yes |
| <a name="input_service_registries"></a> [service\_registries](#input\_service\_registries) | Service discovery registries to attach to the service. AWS currently only supports a single registry. | `map(string)` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets to attach task network interfaces to | `list(string)` | n/a | yes |
| <a name="input_taskdef_cpu"></a> [taskdef\_cpu](#input\_taskdef\_cpu) | CPU units to allocate to the task | `number` | n/a | yes |
| <a name="input_taskdef_execution_role_arn"></a> [taskdef\_execution\_role\_arn](#input\_taskdef\_execution\_role\_arn) | Execution role for ECS to use when provisioning the tasks. Used for things like pulling ecr images, emitting logs, getting secrets to inject, etc. | `string` | n/a | yes |
| <a name="input_taskdef_family"></a> [taskdef\_family](#input\_taskdef\_family) | Task Definition name which is then versioned. Should match the service name. | `string` | n/a | yes |
| <a name="input_taskdef_memory"></a> [taskdef\_memory](#input\_taskdef\_memory) | MB of memory to allocate to the task | `number` | n/a | yes |
| <a name="input_taskdef_network_mode"></a> [taskdef\_network\_mode](#input\_taskdef\_network\_mode) | Network mode for task network interfaces, should always be awsvpc for Fargate | `string` | `"awsvpc"` | no |
| <a name="input_taskdef_requires_compatibilities"></a> [taskdef\_requires\_compatibilities](#input\_taskdef\_requires\_compatibilities) | ECS compatibilities to help determine task placement | `list(string)` | <pre>[<br>  "FARGATE"<br>]</pre> | no |
| <a name="input_taskdef_task_role_arn"></a> [taskdef\_task\_role\_arn](#input\_taskdef\_task\_role\_arn) | Role attached to ECS tasks to give them access to resources | `string` | n/a | yes |
| <a name="input_trusted_account_numbers"></a> [trusted\_account\_numbers](#input\_trusted\_account\_numbers) | List of 12-digit AWS account numbers which can assume the IAM Role which has rights to trigger the CodeDeploy Deployment. This can be used to allow the CodeDeploy to be triggered from another account(s). String type for use in IAM policy. | `list(string)` | n/a | yes |
| <a name="input_use_custom_capacity_provider_strategy"></a> [use\_custom\_capacity\_provider\_strategy](#input\_use\_custom\_capacity\_provider\_strategy) | Boolean to enable a custom capacity provider strategy for the ecs service. This would be used to utilize Fargate Spot for instance. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codepipeline_variables"></a> [codepipeline\_variables](#output\_codepipeline\_variables) | Map for values needed for CodePipeline to do deploys on this service |

---

## Contributors
- Chris Hurst [StratusChris](https://github.com/StratusChris)
- Chris Childress [chrischildresssg](https://github.com/chrischildresssg)

## Ideas for future enhancements
- Potentially make the kms key optional to better support same account options with less inputs?
- Have the iam-cicd-account iam resources be optional and default to not creating via count
- Move autoscaling into the module. To add autoscaling to module, I would:
  - Move the appautoscaling target and policy into the module
  - Have two policies which it selects based off of a string or didn't do if set to false (or left blank?) on autoscaling
- Put the initialization container definition into the module by making it an optional variable which has a local with the config so it matches ports and then coalesces the value
- Add in other codedeploy strategies?


Note, manual changes to the README will be overwritten when the documentation is updated. To update the documentation, run `terraform-docs -c .config/.terraform-docs.yml .`
<!-- END_TF_DOCS -->