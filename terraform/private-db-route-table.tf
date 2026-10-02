resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws-3tier-db-rt"
    Tier = "database"
  }

}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db-a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db-b.id
  route_table_id = aws_route_table.db.id
}