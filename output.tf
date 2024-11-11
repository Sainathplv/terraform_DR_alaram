output "primary_vpc_id" {
  value = aws_vpc.primary_vpc.id
}

output "secondary_vpc_id" {
  value = aws_vpc.secondary_vpc.id
}

output "primary_instance_id" {
  value = aws_instance.primary_instance.id
}

output "secondary_instance_id" {
  value = aws_instance.secondary_instance.id
}

output "primary_lb_dns" {
  value = aws_lb.primary_lb.dns_name
}

output "secondary_lb_dns" {
  value = aws_lb.secondary_lb.dns_name
}
