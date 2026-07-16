terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }

  # State lives in the shared bucket owned by aws-foundation, under this repo's own
  # prefix — the only prefix the deploy role is allowed to touch.
  backend "s3" {
    bucket       = "warewise-tfstate-224193574799"
    key          = "aws-api-gateway/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "product_service_url" {
  description = "External service /api/product/* is proxied to."
  type        = string

  # ponytail: placeholder — httpbin echoes the request back, so the proxy route is
  # verifiable end to end. Swap for the real service URL when it exists.
  default = "https://httpbin.org/anything"
}
