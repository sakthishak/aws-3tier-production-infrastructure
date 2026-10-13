output "alb_dns_name" {
description = "DNS name of the Application Load Balancer"
value       = aws_lb.main.dns_name
}

output "application_url" {
description = "HTTP URL for accessing the application through the ALB"
value       = "http://${aws_lb.main.dns_name}"
}

output "application_private_ip" {
description = "Private IP address of the application EC2 instance"
value       = aws_instance.app.private_ip
}

output "target_group_arn" {
description = "ARN of the application target group"
value       = aws_lb_target_group.app.arn
}
