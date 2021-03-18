provider "aws" {
  region = "us-east-2"
}

terraform {
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
  source = "github.com/huangdgm/modules//services/webserver-cluster?ref=v0.0.1"

  cluster-name = "webservers-prod"
  db_remote_state_bucket = "terraform3-up-and-running"
  db_remote_state_key = "prod/data-storage/mysql/terraform.tfstate"
  webserver_remote_state_bucket = "terraform3-up-and-running"
  webserver_remote_state_key = "prod/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 5
}

resource "aws_autoscaling_schedule" "scale_out_during_biz_hours" {
  autoscaling_group_name = module.webserver-cluster.asg_name
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 5
  desired_capacity = 3
  recurrence = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  autoscaling_group_name = module.webserver-cluster.asg_name
  scheduled_action_name = "scale-in-at-night"
  min_size = 2
  max_size = 5
  desired_capacity = 2
  recurrence = "0 17 * * *"
}