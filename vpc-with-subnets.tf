# VPC
resource "aws_vpc" "albtf_main" {
  cidr_block = "10.0.0.0/23"
  tags = {
    Name = "albtf-vpc"
  }
}

# Public Subnet 1
resource "aws_subnet" "albtf_subnet_1a" {
  vpc_id                    = aws_vpc.albtf_main.id
  cidr_block                = "10.0.0.0/27"
  map_public_ip_on_launch   = true
  availability_zone         = "eu-west-2"
}

# Public Subnet 2
resource "aws_subnet" "albtf_subnet_1b" {
  vpc_id                    = aws_vpc.albtf_main.id
  cidr_block                = "10.0.0.32/27"
  map_public_ip_on_launch   = true
  availability_zone         = "eu-west-1"
}

# Private Subnet
resource "aws_subnet" "albtf_subnet_2" {
  vpc_id                    = aws_vpc.albtf_main.id
  cidr_block                = "10.0.1.0/27"
  map_public_ip_on_launch   = false
  availability_zone         = "eu-west-1"
}