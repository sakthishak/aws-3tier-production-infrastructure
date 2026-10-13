resource "aws_lb" "main" {
  name               = "aws-3tier-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public-a.id, aws_subnet.public-b.id]

  tags = {
    Name = "aws-3tier-alb"
    Tier = "public"
  }
}