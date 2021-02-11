resource "aws_lb_target_group" "default" {
  count                = module.this.enabled ? 1 : 0
  name                 = var.target_group_name == "" ? module.this.id : var.target_group_name
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_group_target_type
  deregistration_delay = var.deregistration_delay

  health_check {
    protocol            = var.target_group_protocol
    path                = var.health_check_path
    port                = var.health_check_port
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
  }

  dynamic "stickiness" {
    for_each = var.stickiness == null ? [] : [var.stickiness]
    content {
      type            = "lb_cookie"
      cookie_duration = stickiness.value.cookie_duration
      enabled         = var.target_group_protocol == "TCP" ? false : stickiness.value.enabled
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    module.this.tags,
    var.target_group_additional_tags
  )
}

resource "aws_lb_listener_rule" "http_forward" {
  count        = module.this.enabled ? 1 : 0
  listener_arn = var.http_listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = join("", aws_lb_target_group.default.*.arn)
  }

  condition {
    path_pattern {
      values = var.listener_rule_path_pattern
    }
  }
}

resource "aws_lb_listener_rule" "https_forward" {
  count        = module.this.enabled ? 1 : 0
  listener_arn = var.https_listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = join("", aws_lb_target_group.default.*.arn)
  }

  condition {
    path_pattern {
      values = var.listener_rule_path_pattern
    }
  }
}