provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster-name = "webservers-prod"
  db_remote_state_bucket = "terraform3-up-and-running"
  db_remote_state_key = "prod/data-storage/mysql/terraform.tfstate"
  webserver_remote_state_bucket = "terraform3-up-and-running"
  webserver_remote_state_key = "prod/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 5
}