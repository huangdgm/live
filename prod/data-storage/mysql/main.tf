provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Allow any 3.33.x version of the AWS provider
      version = "~> 3.33.0"
    }
  }

  required_version = "=1.0.2"

  # Only the 'key' parameter remains in the Terraform code, since you still need to set a different 'key' value for each module.
  # All the other repeated 'backend' arguments, such as 'bucket' and 'region', into a separate file called backend.hcl.
  backend "s3" {
    # Terraform will create the key path automatically
    key = "prod/data-storage/mysql/terraform.tfstate"
  }
}

//
//data "aws_secretsmanager_secret_version" "db_password" {
//  secret_id = "mysql-master-password-stage"
//}

resource "aws_db_instance" "example" {
  instance_class = "db.t2.micro"
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 5
  name = "example_database"
  skip_final_snapshot = true
  username = "admin"

  # Use a Terraform data source to read the secrets from a secret store
  # password = data.aws_secretsmanager_secret_version.db_password.secret_string
  password = "administrator"
}