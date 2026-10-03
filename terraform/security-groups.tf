#-------------------------------------------------------
# ALB Security Group
#Allows internet traffic to reach the load balancer
#-------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "aws 3tier-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws 3tier-alb-sg"
    Tier = "public"
  }
}


#-------------------------------------------------------
#Application Server Security Group
#Allows application traffic only from the ALB security group
#-------------------------------------------------------    

resource "aws_security_group" "app" {
  name        = "aws 3tier-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws 3tier-app-sg"
    Tier = "application"
  }
}

#-------------------------------------------------------
#Database Server Security Group
#Allows postgreSQL traffic only from the application tier
#-------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "aws 3tier-db-sg"
  description = "Security group for database servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL traffic from application servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws 3tier-db-sg"
    Tier = "database"
  }
}
