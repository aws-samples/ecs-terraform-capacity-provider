resource "aws_cloudwatch_log_group" "ec2" {
  for_each          = var.services
  name              = "ec2-${each.key}"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "ec2" {
  for_each                 = var.fargate_only == true ? {} : var.services
  family                   = each.key
  container_definitions    = <<EOF
[
  {
    "name": "ec2-${each.key}",
    "image": "${each.value.image}",
    "cpu": ${each.value.cpu},
    "memory": ${each.value.memory},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "us-east-2",
        "awslogs-group": "ec2-${each.key}",
        "awslogs-stream-prefix": "${each.key}"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "main" {
  for_each        = var.fargate_only == true ? {} : var.services
  name            = "ec2-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ec2[each.key].arn
  desired_count   = each.value.desired_count

  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent

  ordered_placement_strategy {
      type  = "binpack"
      field = "memory"
  }

  capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.main[0].name
      weight            = 1
  }
}