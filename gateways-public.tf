# Internet Gateway
resource "aws_internet_gateway" "albtf_gw" {
  vpc_id = aws_vpc.albtf_main.id
}

# Route Table - Public Gateway
resource "aws_route_table" "albtf_rt_public" {
  vpc_id = aws_vpc.albtf_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.albtf_gw.id
  }
}

# Associate Subnet 1a with Route Table
resource "aws_route_table_association" "albtf_rt1" {
  subnet_id      = aws_subnet.albtf_subnet_1a.id
  route_table_id = aws_route_table.albtf_rt_public.id
}

# Associate Subnet 1b with Route Table
resource "aws_route_table_association" "albtf_rt2" {
  subnet_id      = aws_subnet.albtf_subnet_1b.id
  route_table_id = aws_route_table.albtf_rt_public.id
}