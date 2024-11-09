terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.62.0"
        }
    }
}

provider "aws" {
    region = "ap-southeast-2"  # Change this to your preferred region
}

data "http" "my_ip" {
    url = "http://checkip.amazonaws.com/"
}

resource "tls_private_key" "tls_velo" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_velo" {
    key_name   = var.case_name
    public_key = tls_private_key.tls_velo.public_key_openssh
}

resource "local_file" "private_key" {
    content         = tls_private_key.tls_velo.private_key_pem
    filename        = "${var.case_name}.pem"
    file_permission = "0400"
}

resource "local_file" "ansible_inventory" {
    filename = "./inventory"
    content  = <<EOF
[ubuntu]
${aws_instance.instance_velo.public_ip}

[ubuntu:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=./${var.case_name}.pem
EOF
}

resource "aws_security_group" "secgroup_velo" {
    name = var.case_name
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    tags = {
        Name = var.case_name
    }
}

resource "aws_security_group_rule" "group_velo_ssh" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_group_id = aws_security_group.secgroup_velo.id
    cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]
}

resource "aws_security_group_rule" "group_velo_frontend" {
    type              = "ingress"
    from_port         = 8000
    to_port           = 8000
    protocol          = "tcp"
    security_group_id = aws_security_group.secgroup_velo.id
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "group_velo_gui" {
    type              = "ingress"
    from_port         = 8889
    to_port           = 8889
    protocol          = "tcp"
    security_group_id = aws_security_group.secgroup_velo.id
    cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]
}

resource "aws_instance" "instance_velo" {
    ami               = "ami-0f2bbb476b5c42526" # Update for your region
    key_name          = aws_key_pair.ssh_velo.key_name
    instance_type     = "m5.large"
    vpc_security_group_ids = [aws_security_group.secgroup_velo.id]
    tags = {
        Name = var.case_name
    }
    root_block_device {
        volume_size = "1024"
    }
    provisioner "local-exec" {
        command = "echo $'\nssh -i ${var.case_name}.pem ubuntu@${aws_instance.instance_velo.public_ip}' >> aws-deploy.sh"
    }
}
