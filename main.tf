provider "aws" {
  region  = var.region
}

data "aws_subnet" "default_1" {
  id = var.subnet_id_1
}

data "aws_subnet" "default_2" {
  id = var.subnet_id_2
}

data "aws_security_group" "default" {
  id = var.security_group_id
}

resource "aws_lb" "main" {
  name               = var.prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.default.id]
  subnets            = [
    data.aws_subnet.default_1.id,
    data.aws_subnet.default_2.id
  ]

  tags = {
    Environment = "test"
  }
}

resource "aws_lb_target_group" "main" {
  name     = var.prefix
  port     = 80
  protocol = "HTTP"
}

resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.instance_2.id
  port             = 80
}
