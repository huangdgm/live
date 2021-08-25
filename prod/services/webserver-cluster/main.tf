provider "aws" {
  region = "us-east-2"
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
    # Terraform will create the key path automatically.
    # Variables aren't allowed in a backend configuration.
    key = "prod/services/webserver-cluster/terraform.tfstate"
  }
}

module "webserver-cluster" {
  # Instead of using local source, it is a better practice to use versioned source.
  source = "github.com/huangdgm/modules//modules/services/hello-world-app?ref=v0.0.g"

  db_remote_state_bucket = "terraform3-up-and-running"
  db_remote_state_key = "prod/data-storage/mysql/terraform.tfstate"
  #webserver_remote_state_bucket = "terraform3-up-and-running"
  #webserver_remote_state_key = "prod/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 5
  enable_autoscaling = true
  enable_new_user_data = false

  environment = "prod"
}
