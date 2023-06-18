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

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "description"
    values = ["Amazon Linux 2023 AMI 2023*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

data "template_file" "user_data" {
  template = file("./scripts/setup-nginx.yaml")
}

resource "aws_instance" "web_1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.default_1

  user_data = data.template_file.user_data.rendered

  key_name = var.key_name

  tags = {
    owner = var.owner
  }
}

resource "aws_instance" "web_2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.default_2

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
