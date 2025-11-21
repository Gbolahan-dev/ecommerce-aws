# iam.tf

# 1. IAM Role that our ECS Tasks will assume.
#    This allows the ECS service to perform actions on our behalf.
resource "aws_iam_role" "ecs_task_execution_role_v2" {
  name = "ecs-execution-role-v2"

  # This "assume role policy" says "I trust the AWS ECS Tasks service to use me".
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach the standard AWS-managed policy to the role.
#    This policy grants all the necessary permissions for an ECS task to
#    start up, pull an image from ECR, and send logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role_v2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
