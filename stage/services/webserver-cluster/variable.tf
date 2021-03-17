variable "server_port" {
	description = "The port the web server will use for HTTP requests"
	type = number
	default = 80
}

variable "alb_listener_port" {
	description = "The port the alb will use for HTTP requests"
	type = number
	default = 80
}

variable "region" {
	type = string
	default = "us-east-2"
}

variable "bucket" {
	description = "The S3 bucket to be used for storing state files"
	type = string
	default = "terraform3-up-and-running"
}
