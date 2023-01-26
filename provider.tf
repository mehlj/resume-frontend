terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "mehlj-state"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mehlj_state_locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}