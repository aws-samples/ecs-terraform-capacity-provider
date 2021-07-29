resource "aws_cloudwatch_log_group" "fargate" {
  for_each          = var.services
  name              = "fargate-${each.key}"
  retention_in_days = 1
}

resource "aws_ecs_service" "fargate" {
  for_each        = var.services
  name            = "fargate-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fargate[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = each.value.desired_count
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
}

resource "aws_ecs_task_definition" "fargate" {
  for_each                 = var.services
  family                   = "fargate-${each.key}"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task.arn
  container_definitions    = <<EOF
[
  {
    "name": "fargate-${each.key}",
    "image": "${each.value.image}",
    "cpu": ${each.value.cpu},
    "memory": ${each.value.memory},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "us-east-2",
        "awslogs-group": "fargate-${each.key}",
        "awslogs-stream-prefix": "${each.key}"
      }
    }
  }
]
EOF
}