## Changes
- Removed pipeline
- Changed some variables to be more accurately named
- Made log retention optional with a 30 day default
- Moved cluster code out of module
- Enabled Container Insights on the cluster
- Flattened the module so it wasn't using objects nested in maps and for_each so we can for_each in the root module instead
- Move CodeDeploy role into module

## DONE
- Create this in our dev environment to help test.

## TODO
- Remove KMS and S3 code from this module if it is not needed for cross account deploy
- Have the iam-cicd-account iam resources be optional and default to not creating via count
- Add in role creation for codepipeline if needed that takes a policy and trusted account(s) it should allow to deploy the clusters
- Output a map that is everything needed for the codepipeline module
- Move autoscaling into the module
  /* to add autoscaling to module, I would:
- Move the appautoscaling target and policy into the module
- have two policies which it selected based off of a string or didn't do if set to false on autoscaling
- Add inputs
  max_capacity
  min_capacity
  scale in cooldown
  scale out cooldown
  target value
  predefined metric type
  policy type
*/
- Put the initialization container definition into the module by making it an optional variable which has a local with the config so it matches ports and then coalesces the value
- Update readme, tfdocs, and examples

## MAYBE TODO
- Add in other codedeploy strategies?
- Provide the example with us creating the container definition in terraform and then doing a json encode?
- Move to a centralized TF State Bucket

## CodePipeline Module Inputs
- Should take a map of environments with the following attributes
  - environment name (key for map)
  - s3 bucket path
    - bucket
    - key for zip
    - (optional) taskdef file name
    - (optional) appspec file name
  - codepipeline assumable iam role name
  - codedeploy deployment group name

# ecs-fargate-service

ecs-fargate-service is used to create an ecs service and the corresponding codedeploy, log groups, codepipeline artifacts,
etc. It is intended to be used with StratusGrid's multi-account ecs pipeline module to allow for container images to be 
passed immutably from cluster to cluster in different environments and accounts in a single contiguous pipeline.

For this purpose, ecs-fargate-service outputs a map which can be used to provide configuration for an environment stage
when provisioning the pipeline.

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->