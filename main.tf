provider "aws" {
  region = var.region
}

data "aws_vpc" "main" {
  id = var.vpc_id
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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "user_data" {
  template = file("./scripts/setup-nginx.yaml")
}

resource "aws_instance" "web_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = data.template_file.user_data.rendered

  key_name = var.key_name

  tags = {
    owner = var.owner
  }
}

resource "aws_instance" "web_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = data.template_file.user_data.rendered

  key_name = var.key_name

  tags = {
    owner = var.owner
  }
}

resource "aws_lb" "main" {
  name               = var.prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.default.id]
  subnets = [
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
  vpc_id   = data.aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}
