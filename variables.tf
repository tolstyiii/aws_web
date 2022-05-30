variable "region" {
  default = "eu-central-1"
}

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
      name = "public_ingress1"
      cidr = "192.168.0.0/24"
    },
    {
      name = "public_ingress2"
      cidr = "192.168.1.0/24"
    }
  ]
}

variable "private_subnets" {
  default = [
    {
      name = "web_servers"
      cidr = "192.168.4.0/24"
    }
  ]
}

variable "enable_nat_gateway" {
  default = true
}

variable "source_ssh_ip_enabled" {
}

variable "vm_name" {
  default = "websrv"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ssh_public_key" {
  type        = string
  description = "Public key to import ot EC2"  
}

variable "instance_number_to_allow_ssh" {
  default = 1
}