provider "aws" {
  region = "us-east-2"
}

terraform {
  # Only the 'key' parameter remains in the Terraform code, since you still need to set a different 'key' value for each module.
  # All the other repeated 'backend' arguments, such as 'bucket' and 'region', into a separate file called backend.hcl.
  backend "s3" {
    # Terraform will create the key path automatically.
    # Variables aren't allowed in a backend configuration.
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster-name = "webservers-stage"
  db_remote_state_bucket = "terraform3-up-and-running"
  db_remote_state_key = "stage/data-storage/mysql/terraform.tfstate"
  webserver_remote_state_bucket = "terraform3-up-and-running"
  webserver_remote_state_key = "stage/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 3
}