# Elastic IP for NAT Gateway
resource "aws_eip" "albtf_eip" {
  depends_on    = [ aws_internet_gateway.albtf_gw ]
  #vpc           = true
  domain = "vpc"
  tags = {
    Name = "albtf_EIP_for_NAT"
  }
}

# NAT Gateway for Private Subnets
resource "aws_nat_gateway" "albtf_nat_for_private_subnet" {
  allocation_id = aws_eip.albtf_eip.id
  subnet_id     = aws_subnet.albtf_subnet_1a.id

  tags = {
    Name = "ALBF NAT for private subnet"
  }

  depends_on = [ aws_internet_gateway.albtf_gw ]
}

# Route Table
resource "aws_route_table" "albtf_rt_private" {
  vpc_id = aws_vpc.albtf_main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.albtf_nat_for_private_subnet.id
  }
}

# Associate Subnet 2 with Route Table
resource "aws_route_table_association" "albtf_rt3" {
  subnet_id = aws_subnet.albtf_subnet_2.id
  route_table_id = aws_route_table.albtf_rt_private.id
}