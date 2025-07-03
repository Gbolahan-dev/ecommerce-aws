# alb.tf

# 1. Create the Application Load Balancer (ALB)
resource "aws_alb" "main" {
  name               = "ecommerce-alb"
  internal           = false # This means it's internet-facing
  load_balancer_type = "application"
  # We need to create a Security Group to allow HTTP traffic to the ALB
  security_groups    = [aws_security_group.lb_sg.id]
  # The ALB must be placed in our public subnets to be accessible from the internet
  subnets            = module.vpc.public_subnets

  tags = {
    Name    = "ecommerce-alb"
    Project = "ecommerce-aws"
  }
}

# 2. Create the Security Group for the ALB
resource "aws_security_group" "lb_sg" {
  name        = "ecommerce-lb-sg"
  description = "Allow HTTP inbound traffic to the ALB"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound HTTP traffic from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-lb-sg"
  }
}

# 3. Create a default Target Group
# This is where the ALB will send traffic. Our ECS service will register its tasks here.
# We will create a "dummy" target group for now, as ECS will manage the real targets.
resource "aws_alb_target_group" "default" {
  name     = "ecommerce-default-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type       = "ip"

  health_check {
    path = "/" # The ALB will check this path to see if the target is healthy
    matcher = "200-400"
}

  lifecycle {
     create_before_destroy = true
  }
}

# 4. Create the ALB Listener
# This tells the ALB to listen on port 80 and forward traffic to our default target group.
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }
}
