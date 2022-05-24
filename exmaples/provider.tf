# terraform {
#   required_version = "0.12.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#     }
#   }
# }

provider "aws" {
  version = "~> 3.0"
  region = "eu-central-1"
}