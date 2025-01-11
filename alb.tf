# Create ACM certificate
resource "aws_acm_certificate" "wordpress" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "wordpress-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  # TODO This is just for leaving the ability to go on http for testing but should be removed in favour of redirect block
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
  # TODO Uncomment this and remove the default_action above to enable https only
  #   default_action {
  #     type = "redirect"
  #     redirect {
  #       port        = "443"
  #       protocol    = "HTTPS"
  #       status_code = "HTTP_301"
  #     }
  #   }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.wordpress.arn

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

# Output the DNS records needed for ACM validation
output "acm_validation_records" {
  description = "DNS records to create for ACM certificate validation"
  value = {
    for dvo in aws_acm_certificate.wordpress.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
}
