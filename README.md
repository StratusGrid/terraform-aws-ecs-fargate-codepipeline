# ecs-fargate
ecs-fargate-codepipeline creates an end to end fargate cluster with a single task (but can be multiple containers in the task), a CodeDeploy application deployment configuration, a CodePipeline to wrap around it, and all relevant iam roles etc.

### NOTE:

If you get a Cycle: Error: on destroy, go remove the LB target group that is getting changes first.
```
terraform apply -target aws_lb_target_group.data_hub_web_http
```

If you get errors about the artifact.zip files, you must create the resources which get pulled into the file first, by targeting the iam roles and target groups.

```
terraform apply -target aws_lb_target group.<blue_target_group> -target aws_lb_target_group.<green_target_group>
terraform apply -target module.<ecs_iam_role1> -target module.<ecs_iam_role2>
```

### Example Usage:
Create a cluster with a single service, mapped to a single task, which has a single container:
```
module "ecs_app_iam_role" {
  source  = "GenesisFunction/ecs-iam-role-builder/aws"
  version = "1.0.0"
  # source  = "github.com/GenesisFunction/terraform-aws-ecs-iam-role-builder"
  # source = "./modules/ecs-iam-role-builder"

  cloudwatch_logs_policy     = true
  cloudwatch_logs_group_path = module.ecs_fargate_app.log_group_path

  ecr_policy = true
  ecr_repos  = [
    aws_ecr_repository.app.arn
  ]

  custom_policy_jsons = [data.aws_iam_policy_document.qa_automation_bucket_access.json, data.aws_iam_policy_document.data_hub_ssm_parameters.json]
  
  role_name  = "${var.name_prefix}-app${local.name_suffix}"
  input_tags = merge(local.common_tags, {})
}


resource "aws_service_discovery_private_dns_namespace" "discovery_namespace" {
  name        = "discovery.${var.env_name}.mydomain.com"
  description = "My services ${var.env_name} discovery namespace"
  vpc         = data.aws_vpc.venue_ott_microservices.id

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
  version = "0.1.1"
  # source  = "github.com/StratusGrid/terraform-aws-ecs-fargate-codepipeline"

  ecs_cluster_name   = "${var.name_prefix}-app${local.name_suffix}"
  log_retention_days = 30
  vpc_id             = module.vpc_qa_automation.vpc_id

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
      security_groups  = [aws_security_group.qa_automation_admin.id, aws_security_group.data_hub_web.id]
      subnets          = module.vpc_qa_automation.public_subnets
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
    "image": "469111357076.dkr.ecr.us-east-1.amazonaws.com/qaa-app-qa:latest",
    "essential": true,
    "cpu": 256,
    "memory": 512,
    "memoryReservation": 512,
    "secrets": [
      {"name": "pgdatabase","valueFrom": "${aws_ssm_parameter.data_hub_pgdatabase.arn}"},
      {"name": "pguser","valueFrom": "${aws_ssm_parameter.data_hub_pguser.arn}"},
      {"name": "pgpassword","valueFrom": "${aws_ssm_parameter.data_hub_pgpassword.arn}"},
      {"name": "pg_host","valueFrom": "${aws_ssm_parameter.data_hub_pg_host.arn}"},
      {"name": "pg_port","valueFrom": "${aws_ssm_parameter.data_hub_pg_port.arn}"},
      {"name": "secret_key","valueFrom": "${aws_ssm_parameter.data_hub_secret_key.arn}"},
      {"name": "cipherkey","valueFrom": "${aws_ssm_parameter.data_hub_cipherkey.arn}"}
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
