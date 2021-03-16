provider "aws" {
	region = "us-east-2"
}

terraform {
	# Only the 'key' parameter remains in the Terraform code, since you still need to set a different 'key' value for each module.
	# All the other repeated 'backend' arguments, such as 'bucket' and 'region', into a separate file called backend.hcl.
	backend "s3" {
		# Terraform will create the key path automatically
		key = "global/s3/terraform.tfstate"
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