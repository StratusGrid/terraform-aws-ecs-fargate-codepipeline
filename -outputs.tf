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
    artifact_kms_key_arn             = var.codepipeline_source_bucket_kms_key_arn
    artifact_taskdef_file_name       = local.artifact_taskdef_file_name
    artifact_appspec_file_name       = local.artifact_appspec_file_name
    codedeploy_deployment_group_arn  = aws_codedeploy_deployment_group.this.arn
    codedeploy_deployment_group_name = aws_codedeploy_deployment_group.this.app_name
    codedeploy_deployment_app_arn    = aws_codedeploy_app.this.arn
    codedeploy_deployment_app_name   = aws_codedeploy_app.this.name
    trusting_account_role            = aws_iam_role.cicd_account_role.arn
  }
}
