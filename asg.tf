resource "aws_autoscaling_group" "main" {
  count               = var.fargate_only == false ? 1 : 0
  name                = var.ecs_name
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.private_subnets == [] ? module.vpc[0].private_subnets : var.private_subnets


  launch_template {
    id      = aws_launch_template.main[0].id
    version = aws_launch_template.main[0].latest_version
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.rolling_healthy_percentage
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = var.ecs_name
  }
}

resource "aws_launch_template" "main" {
  count = var.fargate_only == false ? 1 : 0
  name  = var.ecs_name
  image_id      = "ami-03921a191ab15cae7"
  instance_type = var.instance_type
  user_data     = base64encode(data.template_file.user_data.rendered)
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs[0].name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.ecs_name
    }
  }
}