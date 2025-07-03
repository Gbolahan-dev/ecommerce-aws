resource "aws_ecr_repository" "app_repo" {
  name                 = "ecommerce-app"
  image_tag_mutability = "MUTABLE" # Allows us to overwrite tags like 'latest'

  image_scanning_configuration {
    scan_on_push = true # Automatically scan images for vulnerabilities on push
  }
}
