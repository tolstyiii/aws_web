output "ssh_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "web_dns_name" {
  value = aws_lb.alb.dns_name
}

output "public_subnets_list_id" {
  value = aws_subnet.public.*.id
}

output "private_subnets_list_id" {
  value = aws_subnet.private.*.id
}

output "security_groups_list_id" {
  value = concat(aws_security_group.public.*.id, aws_security_group.private.*.id)
}