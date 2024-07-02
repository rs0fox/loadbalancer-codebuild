terraform {
 backend "s3" {
  bucket = "rs0fox-loadbalancer-codebuild"
  key = "tfstate/dev-env-lb.tfstate"
  region = "us-east-1"
 }
}