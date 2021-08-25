provider "aws" {
  region = "us-east-2"
}

# To deploy resources across different regions,
# you can define multiple providers in a single tf file, and reference them in the desired resources accordingly.
# resource "aws_instance" "example" {
#   provider = aws.another_region
# }
provider "aws" {
  alias = "another_region"
  region = "us-east-1"
  profile = "account2"  # To explicitly specify within which account to create the resources
  assume_role { # To assume role so that Terraform has the permissions to create the desired resources (can be created within the same account or different account).
    role_arn = "arn:aws:iam::xxx:role/xxx"
    session_name = "demo"
  }
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

  # Only the 'key' parameter remains in the current Terraform configuration, since you still need to set a different 'key' value for each module.
  # All the other repeated 'backend' arguments, such as 'bucket' and 'region', into a separate file called backend.hcl.
  backend "s3" {
    # Terraform will create the key path automatically.
    # Variables aren't allowed in a backend configuration.
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

module "webserver-cluster" {
  # Instead of using local source, it is a better practice to use versioned source.
  # The 'ref' parameter allows you to specify a particular Git commit via its sha1 hash, a branch name, or, as in this example, a specific Git tag.
  # It is recommended using Git tags as version numbers due to the following reasons:
  # Branch names are not stable, as you always get the latest commit on a branch.
  # The sha1 hashes are not very human friendly.
  # The 'ref' enables the stage and prod to use different versions.
  # This source might need to be changed to reflect to the latest structure change in Git.
  source = "github.com/huangdgm/modules//modules/services/hello-world-app?ref=v0.0.h"

  ami = "ami-07a0844029df33d7d"
  server_text = "New server text"
  db_remote_state_bucket = "terraform3-up-and-running"
  db_remote_state_key = "stage/data-storage/mysql/terraform.tfstate"
  #webserver_remote_state_bucket = "terraform3-up-and-running"
  #webserver_remote_state_key = "stage/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 3
  enable_autoscaling = false
  enable_new_user_data = true

  environment = "stage"

  # Custom tags to set on the instance in the ASG
  custom_tags = {
    Owner = "Dong"
    DeployedBy = "Terraform"
    Env = "Stage"
  }
}