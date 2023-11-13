# Auto-Scaling Group with Launch Template

# Launch Template
resource "aws_launch_template" "albtf_ec2_launch_templ" {
  name_prefix   = "albtf_ec2_launch_templ"
  image_id      = "ami-05c13eab67c5d8861"
  instance_type = "t2.micro"
  user_data     = filebase64("user_data.sh")

  network_interfaces {
    associate_public_ip_address = false
    subnet_id = aws_subnet.albtf_subnet_2.id
    security_groups = [aws_security_group.albtf_sg_for_ec2.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ALBTF-Instance"
    }
  }
}

# Auto-Scaling Group
resource "aws_autoscaling_group" "albtf_asg" {
  
  # Number of instances
  desired_capacity  = 1
  max_size          = 1
  min_size          = 1

  # Connect to Target Group
  target_group_arns = [aws_lb_target_group.albtf_alb_tg.arn]

  # Create the EC2 instances in the Private Subnet
  vpc_zone_identifier = [
    aws_subnet.albtf_subnet_2.id
  ]

  launch_template {
    id      = aws_launch_template.albtf_ec2_launch_templ.id
    version = "$Latest"
  }
}