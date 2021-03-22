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
  # Instead of using local source, it is a better practice to use versioned source.
  # The 'ref' parameter allows you to specify a particular Git commit via its sha1 hash, a branch name, or, as in this example, a specific Git tag.
  # It is recommended using Git tags as version numbers due to the following reasons:
  # Branch names are not stable, as you always get the latest commit on a branch.
  # The sha1 hashes are not very human friendly.
  # The 'ref' enables the stage and prod to use different versions.
  source = "github.com/huangdgm/modules//services/webserver-cluster?ref=v0.0.a"

  cluster-name = "webservers-stage"
  db_remote_state_bucket = "terraform3-up-and-running"
  db_remote_state_key = "stage/data-storage/mysql/terraform.tfstate"
  webserver_remote_state_bucket = "terraform3-up-and-running"
  webserver_remote_state_key = "stage/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 3
  enable_autoscaling = false
  enable_new_user_data = true

  # Custom tags to set on the instance in the ASG
  custom_tags = {
    Owner = "Dong"
    DeployedBy = "Terraform"
  }
}