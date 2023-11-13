# Security Group for ELB
resource "aws_security_group" "albtf_sg_for_elb" {
  name   = "albtf_sg_for_elb"
  vpc_id = aws_vpc.albtf_main.id

  # Permit incoming HTTP
  ingress {
    description      = "Allow HTTP requests from all sources"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Permit incoming HTTP
  ingress {
    description      = "Allow HTTPS requests from all sources"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Security Group for EC2 interfaces
resource "aws_security_group" "albtf_sg_for_ec2" {
  name   = "albtf_sg_for_ec2"
  vpc_id = aws_vpc.albtf_main.id

  # Allow incoming HTTP
  ingress {
    description     = "Allow HTTP requests from the Load Balancer"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.albtf_sg_for_elb.id]
  }

  # 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}