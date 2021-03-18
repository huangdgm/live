# To write 'alb_dns_name' into the remote state file, we need to explicitly specify it in the output file(NOT the one under the modules).
output "alb_dns_name" {
  value = module.webserver-cluster.alb_dns_name
  description = "The domain name of the load balancer"
}