# Load Balancer
resource "aws_lb" "albtf-lb-aws_nat_gateway" {
  name                  = "albtf-lb-asg"
  internal              = false
  load_balancer_type    = "application"
  security_groups = [ aws_security_group.albtf_sg_for_elb.id ]
  subnets = [aws_subnet.aws_subnet.albtf_subnet_1a.id, aws_subnet.albtf_subnet_1b.id]
  depends_on = [ aws_internet_gateway.albtf_gw ]
}

# Load Balancer Target Group
resource "aws_lb_target_group" "albtf_alb_tg" {
  name = "albtf-alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.albtf_main.id
}

# Load Balancer Listener
resource "aws_lb_listener" "albtf_front_end" {
  load_balancer_arn = aws_lb.albtf_lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.albtf_alb_tg.arn
  }
}