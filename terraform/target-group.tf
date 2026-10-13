resource "aws_lb_target_group" "app" {
  name     = "aws-3tier-app-tg"
  port     = 8080
  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
  tags = {
    Name = "aws-3tier-app-tg"
    Tier = "application"
  }
}