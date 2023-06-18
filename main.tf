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
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "description"
    values = ["Amazon Linux 2023 AMI*"]
  }
}

data "template_file" "user_data" {
  template = file("./scripts/setup-nginx.sh")
}

resource "aws_instance" "web_1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.default_1.id

  user_data = data.template_file.user_data.rendered

  key_name = var.key_name

  tags = {
    owner = var.owner
  }
}

resource "aws_instance" "web_2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.default_2.id

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

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["example.com"]
    }
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

data "aws_route53_zone" "main" {
  name = "rahmandemo.com."
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "rahmandemo.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${data.aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.main.dns_name]
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 0
  to_port           = 80
  protocol          = "tcp"
  security_group_id = data.aws_security_group.default.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 0
  to_port           = 22
  protocol          = "tcp"
  security_group_id = data.aws_security_group.default.id
  cidr_blocks       = ["0.0.0.0/0"]
}
