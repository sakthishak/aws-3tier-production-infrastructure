resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"


  route_table_ids = [aws_route_table.app.id]

  tags = {
    Name = "aws-3tier-s3-endpoint"
  }
}