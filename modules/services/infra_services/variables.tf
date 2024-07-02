variable "cloud_env" {
 type = string
 description = "Enter the environment (dev/qa/prod)"
}

variable "vpc_cidr" {
 type = string
 description = "Enter the VPC CIDR Value"
}

variable "vpc_tag_name" {
 type = string
 description = "Enter the VPC Tag Value"
}

variable "access_ip" {
 type = string
 default = "103.197.75.241/32"
}

variable "public_cidrs" {
 type = list(string)
 default = ["10.7.1.0/24","10.7.3.0/24"]
}

variable "private_cidrs" {
 type = list(string)
 default = ["10.7.2.0/24","10.7.4.0/24"]
}

variable "instance_type" {
 type = string
 default = "t2.micro"
}

variable "vol_size" {
 type = number
 default = 8
}

variable "instance_key_name" {
 type = string
 default = "hp"
}

variable "instance_count" {
 type = number
 default = 2
}
