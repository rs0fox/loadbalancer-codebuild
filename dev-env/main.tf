module "infra_services" {
 source = "../modules/services/infra_services"
 cloud_env = "dev-env"
 vpc_tag_name = "vpc"
 instance_count = "2"
 instance_type = "t2.micro"
 vpc_cidr = "10.7.0.0/16"
 public_cidrs = ["10.7.1.0/24","10.7.3.0/24"]
 private_cidrs = ["10.7.2.0/24","10.7.4.0/24"]
 instance_key_name = "hp"
 access_ip = "103.197.75.241/32"
 vol_size = "8"
}