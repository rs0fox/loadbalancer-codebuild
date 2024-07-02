data "aws_ami" "server_ami" {
 most_recent = true
 owners = ["amazon"]
 
 filter {
  name = "owner-alias"
  values = ["amazon"]
 }
 
 filter {
  name = "name"
  values = ["amzn2-ami-hvm*-x86_64-gp2"]
 }
}

resource "aws_instance" "test_lb_ec2" {
 count = var.instance_count
 instance_type = var.instance_type
 ami = data.aws_ami.server_ami.id
 key_name = var.instance_key_name
 
 user_data = <<-EOF
             #!/bin/bash
			 sudo su
			 yum update -y
			 yum install -y httpd.x86_64
			 systemctl start httpd.service
			 systemctl enable httpd.service
			 echo "Hello World from $(hostname -f)" > /var/www/html/index.html
			 EOF
			 
 tags = {
  Name = "${var.cloud_env}_test_lb_ec2_${count.index}"
 }
 vpc_security_group_ids = [aws_security_group.test_lb_ec2_sg.id]
 subnet_id = aws_subnet.test_lb_private_test_subnet[count.index % length(aws_subnet.test_lb_private_test_subnet)].id
 root_block_device {
  volume_size = var.vol_size
 }
}

resource "aws_lb_target_group" "test_lb_tg" {
 name = "test-lb-tg"
 port = 80
 protocol = "HTTP"
 vpc_id = aws_vpc.test_lb_vpc.id
 
 health_check {
  interval = 30
  path = "/"
  port = "traffic-port"
  protocol = "HTTP"
  timeout = 5
  unhealthy_threshold = 2
  healthy_threshold = 2
 }
}

resource "aws_lb_target_group_attachment" "test_lb_tg_attachment" {
 count = 2
 target_group_arn = aws_lb_target_group.test_lb_tg.arn
 target_id = aws_instance.test_lb_ec2[count.index].id
 port = 80
}

data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }

  vpc_id = aws_vpc.test_lb_vpc.id
}

resource "aws_lb" "test_lb" {
 name = "test-lb"
 internal = false
 load_balancer_type = "application"
 security_groups = [aws_security_group.test_lb_sg.id,data.aws_security_group.default.id]
 subnets = aws_subnet.test_lb_public_test_subnet[*].id
 
 tags = {
  Name = "test_lb"
 }
}

resource "aws_lb_listener" "test_lb_listener" {
 load_balancer_arn = aws_lb.test_lb.arn
 port = 80
 protocol = "HTTP"
 
 default_action {
  type = "forward"
  target_group_arn = aws_lb_target_group.test_lb_tg.arn
 }
 
 tags = {
  Name = "test_lb_listener"
 }
}

output "load_balancer_dns" {
 value = aws_lb.test_lb.dns_name
}