resource "aws_vpc" "test_lb_vpc" {
  cidr_block  = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "${var.cloud_env}-${var.vpc_tag_name}"
  }
  
  lifecycle {
   create_before_destroy = true
  }
}

resource "aws_internet_gateway" "test_lb_internet_gateway" {
 vpc_id = aws_vpc.test_lb_vpc.id
 
 tags = {
  Name = "${var.cloud_env}_test_lb_internet_gateway"
 }
}

resource "aws_default_route_table" "test_lb_private_rt" {
 default_route_table_id = aws_vpc.test_lb_vpc.default_route_table_id
 
 tags = {
  Name = "${var.cloud_env}_test_lb_default_private_rt"
 }
}

resource "aws_route" "test_lb_pvt_route" {
 route_table_id = aws_default_route_table.test_lb_private_rt.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id = aws_nat_gateway.test_lb_nat_gw.id
}

resource "aws_route_table" "test_lb_public_rt" {
 vpc_id = aws_vpc.test_lb_vpc.id
 
 tags = {
  Name = "${var.cloud_env}_test_lb_public_route_table"
 }
}

resource "aws_route" "test_lb_test_route" {
 route_table_id = aws_route_table.test_lb_public_rt.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.test_lb_internet_gateway.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "test_lb_public_test_subnet" {
 count = 2
 vpc_id = aws_vpc.test_lb_vpc.id
 cidr_block = var.public_cidrs[count.index]
 map_public_ip_on_launch = true
 availability_zone = data.aws_availability_zones.available.names[count.index]
 
 tags = {
  Name = "${var.cloud_env}_test_lb_public_test_subnet_${count.index}"
 }
}

resource "aws_subnet" "test_lb_private_test_subnet" {
 count = 2
 vpc_id = aws_vpc.test_lb_vpc.id
 cidr_block = var.private_cidrs[count.index]
 map_public_ip_on_launch = false
 availability_zone = data.aws_availability_zones.available.names[count.index]
 
 tags = {
  Name = "${var.cloud_env}_test_lb_private_test_subnet_${count.index}"
 }
}

resource "aws_route_table_association" "test_lb_public_subnet_association" {
 count = 2
 subnet_id = aws_subnet.test_lb_public_test_subnet.*.id[count.index]
 route_table_id = aws_route_table.test_lb_public_rt.id
}

resource "aws_route_table_association" "test_lb_private_subnet_association" {
 count = 2
 subnet_id = aws_subnet.test_lb_private_test_subnet.*.id[count.index]
 route_table_id = aws_default_route_table.test_lb_private_rt.id
}

resource "aws_eip" "test_lb_eip" {
 domain = "vpc"
}

resource "aws_nat_gateway" "test_lb_nat_gw" {
 allocation_id = aws_eip.test_lb_eip.id
 subnet_id = aws_subnet.test_lb_public_test_subnet[0].id
 
 tags = {
  Name = "test_lb_nat_gw"
 }
}

resource "aws_security_group" "test_lb_ec2_sg" {
 name = "${var.cloud_env}_test_lb_ec2_sg"
 description = "security group for private instances"
 vpc_id = aws_vpc.test_lb_vpc.id
}

resource "aws_security_group_rule" "ingress_ssh_ec2" {
 type = "ingress"
 from_port = 22
 to_port = 22
 protocol = "tcp"
 cidr_blocks = [var.access_ip]
 security_group_id = aws_security_group.test_lb_ec2_sg.id
}

resource "aws_security_group_rule" "ingress_http_ec2" {
 type = "ingress"
 from_port = 80
 to_port = 80
 protocol = "tcp"
 source_security_group_id = aws_security_group.test_lb_sg.id
 security_group_id = aws_security_group.test_lb_ec2_sg.id
}

resource "aws_security_group_rule" "egress_all_ec2" {
 type = "egress"
 from_port = 0
 to_port = 65535
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 security_group_id = aws_security_group.test_lb_ec2_sg.id
}

resource "aws_security_group" "test_lb_sg" {
 name = "${var.cloud_env}_test_lb_sg"
 description = "security group for load balancer"
 vpc_id = aws_vpc.test_lb_vpc.id
}

resource "aws_security_group_rule" "ingress_http_lb" {
 type = "ingress"
 from_port = 80
 to_port = 80
 protocol = "tcp"
 cidr_blocks = [var.access_ip]
 security_group_id = aws_security_group.test_lb_sg.id
}

resource "aws_security_group_rule" "egress_all_lb" {
 type = "egress"
 from_port = 0
 to_port = 65535
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 security_group_id = aws_security_group.test_lb_sg.id
}