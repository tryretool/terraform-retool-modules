resource "aws_lb" "this" {
  name               = "${var.deployment_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  idle_timeout       = var.alb_idle_timeout
  tags               = var.tags
}

resource "aws_lb_listener" "this" {
  count             = var.alb_http_redirect ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener" "this_redirect" {
  count             = var.alb_http_redirect ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  count        = var.alb_http_redirect ? 0 : 1
  listener_arn = aws_lb_listener.this[0].arn
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

  tags = var.tags
}
