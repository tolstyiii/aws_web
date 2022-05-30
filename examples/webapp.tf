module web {
  source = "git::https://github.com/tolstyiii/aws_web?ref=v0.1.0"

  region                = "eu-central-1"
  instance_type         = "t2.micro"
  source_ssh_ip_enabled = "<EnterYourPublicIP>"
  ssh_public_key        = "<EnterYourPublicSSHKey>"
}

output "ssh_dns" {
  value = module.web.ssh_dns_name
}

output "web_dns" {
  value = module.web.web_dns_name
}