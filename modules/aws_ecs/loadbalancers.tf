resource "aws_lb" "this" {
  name         = "${var.deployment_name}-alb"
  idle_timeout = var.alb_idle_timeout
  internal     = var.alb_internal

  security_groups = [aws_security_group.alb.id]
  subnets         = var.alb_subnet_ids != null ? var.alb_subnet_ids : var.subnet_ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.alb_certificate_arn == null ? [1] : []

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  dynamic "default_action" {
    for_each = var.alb_certificate_arn != null ? [1] : []

    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.alb_certificate_arn != null ? 1 : 0
  certificate_arn   = var.alb_certificate_arn
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.alb_certificate_arn != null ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group" "this" {
  name                 = "${var.deployment_name}-target"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  port                 = 3000
  protocol             = "HTTP"
  target_type          = var.launch_type == "FARGATE" ? "ip" : "instance"

  health_check {
    interval            = 61
    path                = "/api/checkHealth"
    protocol            = "HTTP"
    timeout             = 60
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}
