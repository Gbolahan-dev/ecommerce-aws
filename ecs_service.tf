# ecs_service.tf

# 1. Security Group for our application containers (ECS Tasks).
#    This will allow traffic from our Load Balancer.
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecommerce-tasks-sg"
  description = "Allow traffic from the ALB to the Fargate containers"
  vpc_id      = module.vpc.vpc_id

  
  ingress {
    description = "Allow traffic from within the VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    # Allow traffic from any IP address inside our VPC
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  # Egress (outbound) rule: Allow the container to make requests to anywhere.
  # This is needed for it to connect to the internet via the NAT Gateway.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-tasks-sg"
  }
}

# 2. ECS Task Definition: The blueprint for our container.
resource "aws_ecs_task_definition" "app" {
  family                   = "ecommerce-app-task"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 256 CPU units (.25 vCPU)
  memory                   = "512"  # 512 MB of memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # This is the definition of the actual container to run
  container_definitions = jsonencode([
    {
      name      = "ecommerce-app",
      # THIS IS THE CORRECTED LINE:
      image     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/ecommerce-app:${var.image_tag}"
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ]
    }
  ])
}

# 3. ECS Service: Runs and maintains our Task Definition.
resource "aws_ecs_service" "main" {
  name            = "ecommerce-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2 # Run two instances of our container for high availability

  launch_type = "FARGATE"

  force_new_deployment = true

  network_configuration {
    # Place our tasks in the private subnets we created
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  # Connect the service to our Application Load Balancer
  load_balancer {
    target_group_arn = aws_alb_target_group.default.arn
    container_name   = "ecommerce-app"
    container_port   = 8080
  }

  # This ensures that Terraform doesn't try to destroy the old service
  # before the new one is healthy and serving traffic.
  #lifecycle { ignore_changes = [task_definition] }
}
