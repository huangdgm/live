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
