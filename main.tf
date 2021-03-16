provider "aws" {
	region = "us-east-2"
}

terraform {
	backend "s3" {
		bucket = "terraform3-up-and-running"
		# Terraform will create the key path automatically
		key = "global/s3/terraform.tfstate"
		region = "us-east-2"

		dynamodb_table = "terraform-up-and-running-locks"
		encrypt = true
	}
}

resource "aws_s3_bucket" "terraform_state" {
	bucket = "terraform3-up-and-running"

	lifecycle {
		prevent_destroy = true
	}

	versioning {
		enabled = true
	}

	server_side_encryption_configuration {
		rule {
			apply_server_side_encryption_by_default {
				sse_algorithm = "AES256"
			}
		}
	}
}

resource "aws_dynamodb_table" "terraform-locks" {
	hash_key = "LockID"
	name = "terraform-up-and-running-locks"
	billing_mode = "PAY_PER_REQUEST"
	attribute {
		name = "LockID"
		type = "S"
	}
}