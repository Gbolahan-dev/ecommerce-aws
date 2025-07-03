# vpc.tf

# This module creates a best-practice VPC, including public and private subnets,
# an internet gateway, and NAT gateways.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = "ecommerce-vpc"

  # The main IP address range for the entire VPC
  cidr = "10.0.0.0/16"

  # Define the availability zones we want our subnets to be in
  azs = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]

  # Define our private subnets
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # Define our public subnets
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  # Create a NAT gateway. This allows containers in the private subnets
  # to make outbound requests to the internet (e.g., to pull dependencies),
  # but the internet cannot initiate connections to them.
  enable_nat_gateway = true
  single_nat_gateway = true # For cost savings in dev/test, use one NAT gateway for all private subnets.

  # Tags are useful for identifying resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "ecommerce-aws"
  }
}

# This data source gets a list of available Availability Zones in the current region
# so we don't have to hardcode them (e.g., "us-east-1a", "us-east-1b").
data "aws_availability_zones" "available" {}
