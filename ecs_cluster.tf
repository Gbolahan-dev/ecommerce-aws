# ecs_cluster.tf

# Create an ECS (Elastic Container Service) Cluster
# This is a logical grouping for our services and tasks.
resource "aws_ecs_cluster" "main" {
  name = "ecommerce-cluster"

  tags = {
    Name    = "ecommerce-cluster"
    Project = "ecommerce-aws"
  }
}
