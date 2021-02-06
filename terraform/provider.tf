terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "config-bucket-100648102620-us-west-2"
    key = "tf/vpc-reference-architecture.tfstate"
  }
}

provider "aws" {
  region = local.region
}