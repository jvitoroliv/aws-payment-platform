# outputs.tf
# Manages output value definitions resources.

output "lb_http_sg_id" {
  description = "Security Group ID of lb_http"
  value       = aws_security_group.lb_http.id
}

output "lb_https_sg_id" {
  description = "Security Group ID of lb_https"
  value       = aws_security_group.lb_https.id
}