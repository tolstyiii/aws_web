variable "vpc_name" {
  default = "aws_vpc01"
}

variable "vpc_cidr" {
  default = "192.168.0.0/20"
}

variable "tags" {
  default = {}
}

variable "instance_tenancy" {
  default = "default"
}

variable "enable_dns_support" {
  default = true
}

variable "enable_dns_hostnames" {
  default = false
}

variable "secondary_cidr_blocks" {
  default = []
}

variable "public_subnets" {
  default = [
    {
      name = "public_ingress"
      cidr = "192.168.0.0/24"
      az   = "eu-central-1b"
    }
  ]
}

variable "private_subnets" {
  default = [
    {
      name = "web_servers"
      cidr = "192.168.2.0/24"
      az   = "eu-central-1c"
    }
  ]
}

variable "enable_nat_gateway" {
  default = true
}

variable "source_ssh_ip_enabled" {
  default = "193.165.113.66/32"
}

variable "vm_name" {
  default = "websrv"
}