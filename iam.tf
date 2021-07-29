resource "aws_iam_role" "ecs" {
  name               = "${var.ecs_name}_ecs"
  assume_role_policy = file("files/iam/ecs_ec2_assume_role.json")
}

resource "aws_iam_instance_profile" "ecs" {
  count = var.fargate_only == false ? 1 : 0
  name  = "${var.ecs_name}_ecs_instance_profile"
  role  = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  count      = var.fargate_only == false ? 1 : 0
  role       = aws_iam_role.ecs.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  count      = var.fargate_only == false ? 1 : 0
  role       = aws_iam_role.ecs.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_cloudwatch_role" {
  count      = var.fargate_only == false ? 1 : 0
  role       = aws_iam_role.ecs.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


resource "aws_iam_role" "task" {
  name_prefix        = "task-logger-"
  assume_role_policy = file("files/iam/task_assume_role.json")
}

resource "aws_iam_role_policy" "task" {
  name_prefix = "task-policy-"
  policy      = file("files/iam/task_policy.json")
  role        = aws_iam_role.task.id
}
