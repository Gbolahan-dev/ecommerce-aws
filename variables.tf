variable "image_tag" {
  description  = "The image tag for the Docker container to deploy."
  type         = string
  default      = "latest" 
}
variable "aws_region" {
  description  = "The AWS region to deploy resources in."
  type         = string
  default      = "us-east-1"
}
variable "aws_account_id" {
  decription  = "The Account ID"
  type        = string 
}
