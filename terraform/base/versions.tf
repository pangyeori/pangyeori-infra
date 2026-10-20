terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80"
    }
  }

  # 버킷 이름은 init 때 넘긴다: terraform init -backend-config=../backend.hcl
  backend "s3" {
    key          = "pangyeori/base.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true # S3 락 파일 사용 (DynamoDB 불필요)
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
