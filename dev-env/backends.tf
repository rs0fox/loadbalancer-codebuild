terraform {
 backend "s3" {
  bucket = "chetan-tfstate"
  key = "tfstate/dev-env-lb.tfstate"
  region = "ap-south-1"
 }
}