provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  count = var.private_subnets == [] ? 1 : 0
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.ecs_name}_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
resource "aws_ecs_cluster" "main" {
  name               = var.ecs_name
  capacity_providers = length(aws_ecs_capacity_provider.main) == 1 ? [aws_ecs_capacity_provider.main[0].name] : []

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }
}

resource "aws_ecs_capacity_provider" "main" {
  count = var.fargate_only == false ? 1 : 0
  name  = var.ecs_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.main[0].arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100

    }
  }
}