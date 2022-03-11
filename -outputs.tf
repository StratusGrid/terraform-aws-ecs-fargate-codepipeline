//output "ecs_cluster_name" {
//  description = "ARN of ECS cluster created by this module."
//  value       = var.ecs_cluster_name
//}

//output "ecs_cluster_arn" {
//  description = "ARN of ECS cluster created by this module."
//  value       = data.aws_ecs_cluster.this.arn
//}
//
//output "codedeploy_app_arns_map" {
//  description = "Map of ARNs of CodeDeploy app created by this module."
//  value = tomap({
//    for k, service in aws_codedeploy_app.this : k => service.arn
//  })
//}

output "codepipeline_variables" {
  description = "Map for values needed for CodePipeline to do deploys on this service"
  value = {
    aws_account_number               = data.aws_caller_identity.current.account_id
    artifact_bucket                  = var.codepipeline_source_bucket_id
    artifact_key                     = var.codepipeline_source_object_key
    artifact_taskdef_file_name       = local.artifact_taskdef_file_name
    artifact_appspec_file_name       = local.artifact_appspec_file_name
    codedeploy_deployment_group_arn  = aws_codedeploy_deployment_group.this.arn
    codedeploy_deployment_group_name = aws_codedeploy_deployment_group.this.id
    cicd_account_role                = aws_iam_role.cicd_account_role.arn
  }
}

//## CodePipeline Module Inputs
//- Should take a map of environments with the following attributes
//  - environment name (key for map)
//  - s3 bucket path
//    - bucket
//    - key for zip
//    - (optional) taskdef file name
//    - (optional) appspec file name
//  - codepipeline assumable iam role name
//  - codedeploy deployment group name