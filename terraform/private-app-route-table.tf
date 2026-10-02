resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws-3tier-app-rt"
    Tier = "application"
  }

}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app-a.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app-b.id
  route_table_id = aws_route_table.app.id
}