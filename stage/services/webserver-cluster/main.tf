provider "aws" {
	region = "us-east-2"
}

data "aws_vpc" "default" {
	# Direct Terraform to lookup the default VPC in your AWS account
	default = true
}

data "aws_subnet_ids" "default" {
	vpc_id = data.aws_vpc.default.id
}

resource "aws_launch_configuration" "example" {
	image_id			= "ami-07a0844029df33d7d"
	instance_type		= "t2.micro"
	security_groups		= [aws_security_group.instance.id]

	user_data = <<-EOF
		    #!/bin/bash
		    sudo yum update -y
			sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
		    sudo yum install -y httpd mariadb-server
		    sudo systemctl start httpd
		    sudo systemctl enable httpd
		    sudo usermod -a -G apache ec2-user
		    sudo chown -R ec2-user:apache /var/www
		    sudo chmod -R 777 /var/www
		    sudo find /var/www -type d -exec chmod 2775 {} \;
		    sudo find /var/www -type f -exec chmod 0664 {} \;
		    sudo echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
		    EOF

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.name
	vpc_zone_identifier = data.aws_subnet_ids.default.ids

	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"

	min_size = 2
	max_size = 3

	tag {
		key = "Name"
		value = "terraform-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_security_group" "instance" {
	name = "terraform-example-instance"

	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_lb" "example" {
	name = "terraform-asg-example"
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.default.ids
	security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.example.arn
	port = 80
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

resource "aws_security_group" "alb" {
	name = "terraform-example-alb"

	# Allow inbound HTTP requests
	ingress {
		from_port = 80
		protocol = "tcp"
		to_port = 80
		cidr_blocks = ["0.0.0.0/0"]
	}

	# Allow all outbound requests
	egress {
		from_port = 0
		protocol = "-1"
		to_port = 0
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_lb_target_group" "asg" {
	name = "terraform-asg-example"
	port = var.server_port
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