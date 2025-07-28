/*terraform {
   backend "s3" {
     bucket         = "tf-state-ecommerce-346032389979"
     key            = "global/s3-backend/terraform.tfstate" 
     region         = "us-east-1"
     dynamodb_table = "terraform-ecommerce-locks"
     encrypt        = true 

  }
   
   required_providers {
     aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
   }
 }
}


provider "aws" {
  region = "us-east-1"
}
*/

