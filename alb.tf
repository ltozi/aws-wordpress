# Get existing ACM certificate
data "aws_acm_certificate" "wordpress" {
  domain   = var.domain_name # Update this to match your domain
  statuses = ["ISSUED"]
}

# ALB Configuration
resource "aws_lb" "wordpress" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    scope = "terraform-worpress"
  }
}

resource "aws_lb_target_group" "wordpress" {
  name        = "wordpress-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled           = true
    healthy_threshold = 2
    interval          = 30
    timeout           = 5
    path              = "/"
    port              = "traffic-port"
    protocol          = "HTTP"
    matcher           = "200,302"
  }

  tags = {
    scope = "terraform-worpress"
  }
}

#TODO This is just for extra test
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.wordpress.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

# Add an output for the ALB DNS name
output "wordpress_urls" {
  description = "WordPress URLs (HTTP and HTTPS)"
  value = {
    http  = "http://${aws_lb.wordpress.dns_name}"
    https = "https://${aws_lb.wordpress.dns_name}"
  }
}
