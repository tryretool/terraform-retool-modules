resource "aws_lb" "this" {
  name         = "${var.deployment_name}-alb"
  idle_timeout = var.alb_idle_timeout

  security_groups = [aws_security_group.alb.id]
  subnets         = var.public_subnet_ids
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = aws_lb_listener.this.arn
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
