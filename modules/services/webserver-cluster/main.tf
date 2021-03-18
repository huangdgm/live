// This was moved to stage and prod.
//terraform {
//	# Only the 'key' parameter remains in the Terraform code, since you still need to set a different 'key' value for each module.
//	# All the other repeated 'backend' arguments, such as 'bucket' and 'region', into a separate file called backend.hcl.
//	backend "s3" {
//		# Terraform will create the key path automatically.
//		# Variables aren't allowed in a backend configuration.
//		key = "stage/services/webserver-cluster/terraform.tfstate"
//	}
//}

# Under the hood, the information provided by data source is fetched by calling AWS API.
data "aws_vpc" "default" {
	# Direct Terraform to lookup the default VPC in your AWS account
	default = true
}

# The [CONFIG] list serves as the filter.
data "aws_subnet_ids" "default" {
	vpc_id = data.aws_vpc.default.id
}

# You can use this data source to fetch the Terraform state file stored by another set of Terraform configurations in a completely read-only manner.
# The way to fetch the data from terraform_remote_state is through 'outputs'.
data "terraform_remote_state" "db" {
	backend = "s3"

	config = {
		bucket = var.db_remote_state_bucket
		key = var.db_remote_state_key
		region = var.region
	}
}

data "terraform_remote_state" "webserver-cluster" {
	backend = "s3"

	config = {
		bucket = var.webserver_remote_state_bucket
		key = var.webserver_remote_state_key
		region = var.region
	}
}

# Externalize the user data file.
data "template_file" "user-data" {
	template = file("${path.module}/user-data.sh")

	// Another way to define variables.
	// These variables are dedicated for the usage by 'user-data.sh'.
	vars = {
		alb_dns_name = data.terraform_remote_state.webserver-cluster.outputs.alb_dns_name
		alb_listener_port	= local.http_port // To reference another variable prefixed with 'var'.
		db_address	= data.terraform_remote_state.db.outputs.address
		db_port		= data.terraform_remote_state.db.outputs.port
	}
}

# Although it is a good practice to use input variables to allow, e.g. stage, prod, to specify their own values,
# we still need a way to define a variable in your module to do some intermediary calculation, or just to keep your code DRY,
# but you don't want to expose that variable as a configurable input.
locals {
	http_port = 80
	any_port = 0
	any_protocol = "-1"
	tcp_protocol = "tcp"
	all_ips = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "example" {
	image_id			= "ami-07a0844029df33d7d"
	instance_type		= var.instance_type
	security_groups		= [aws_security_group.instance.id]
	user_data 			= data.template_file.user-data.rendered

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.name
	vpc_zone_identifier = data.aws_subnet_ids.default.ids

	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"

	min_size = var.min_size
	max_size = var.max_size

	tag {
		key = "Name"
		value = "${var.cluster-name}-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_security_group" "instance" {
	name = "${var.cluster-name}-instance"
}

resource "aws_security_group_rule" "allow_http_inbound_instance" {
	security_group_id = aws_security_group.instance.id
	type = "ingress"

	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound_instance" {
	security_group_id = aws_security_group.instance.id
	type = "egress"

	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
}

# Instead of putting ingress and egress rules as inline blocks, moving them out as separate resources allow you to have extra flexibility to add custom rules from outside the module.
# For example, you export the ID of the 'aws_security_group' as an output variable. And then imagine that in the staging environment, expose an extra port just for testing.
resource "aws_security_group" "alb" {
	name = "${var.cluster-name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound_alb" {
	security_group_id = aws_security_group.alb.id
	type = "ingress"

	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound_alb" {
	security_group_id = aws_security_group.alb.id
	type = "egress"

	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
}

resource "aws_lb" "example" {
	name = "${var.cluster-name}-asg-example"
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.default.ids
	security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.example.arn
	port = local.http_port
	protocol = "HTTP"

	# By default, return a simple 404 page
	default_action {
		type = "fixed-response"

		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = "404"
		}
	}
}

resource "aws_lb_target_group" "asg" {
	name = "${var.cluster-name}-asg-example"
	port = local.http_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id

	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 3
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
}

resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100

	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.asg.arn
	}

	condition {
		path_pattern {
			values = ["*"]
		}
	}
}