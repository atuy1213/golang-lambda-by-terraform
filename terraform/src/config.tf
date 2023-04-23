provider "aws" {
  region  = "ap-northeast-1"
  profile = "<Write Your Profile>"
}

terraform {
  backend "local" {}

  required_version = "~> 1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.64.0"
    }
  }
}