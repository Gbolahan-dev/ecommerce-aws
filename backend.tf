# backend.tf

variable "aws_account_id" {
  description = "Your AWS Account ID"
  type        = string
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tf-state-ecommerce-${var.aws_account_id}"


  versioning {
    enabled = true
  }


 lifecycle {
    prevent_destroy = true
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-ecommerce-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute{
    name = "LockID"
    type = "S"
  }

}
