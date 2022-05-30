module web {
  source = "https://github.com/tolstyiii/aws_web"

  region                = "eu-central-1"
  instance_type         = "t2.micro"
  source_ssh_ip_enabled = "<yourPublicIP>"
  ssh_public_key        = "<publicKey>"
}