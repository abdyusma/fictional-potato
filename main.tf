provider "aws" {
  region  = var.region
}

data "aws_subnet" "default" {
  id = var.subnet_id
}

data "aws_security_group" "default" {
  id = var.security_group_id
}

resource "aws_lb" "main" {
  name               = var.prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.default.id]
  subnets            = [data.aws_subnet.default.id]

  tags = {
    Environment = "test"
  }
}
