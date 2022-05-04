provider "aws" {
access_key = "${var.access_key}"
secret_key = "${var.secret_key}"
region = "${var.region}"	
}
/*
#vpc#
resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"
  
  tags = {
    Name = "K8s_vpc"
  }
}
#sg#
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
  
  ingress {
    description = "SSH from VPC"
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "kube api"
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "kubelet"
    protocol  = "tcp"
    from_port = 10250
    to_port   = 10250
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "kube-scheduler"
    protocol  = "tcp"
    from_port = 10251
    to_port   = 10251
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "kube-controller-manager"
    protocol  = "tcp"
    from_port = 10252
    to_port   = 10252
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "etcd"
    protocol  = "tcp"
    from_port = 2379
    to_port   = 2380
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "k8s_Worker_sg"
  }	
}
#subnets#
resource "aws_subnet" "pub_sub" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = var.availability_zone_names
  map_public_ip_on_launch = true
  
#  depends_on = [aws_internet_gateway.gw]
  
  tags = {
    Name = "k8s_public_subnet"
  }
}
resource "aws_subnet" "pri_sub" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "172.16.2.0/24"
  availability_zone = var.availability_zone_names
  
  
  tags = {
    Name = "k8s_private_subnet"
  }
}
#igw#
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "k8s_igw"
  }
}
#igw_attach#
resource "aws_internet_gateway_attachment" "igw_attach" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id = aws_vpc.vpc.id  
} 
#rt_table#
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "k8s_public_rt"
  }	
}
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.vpc.id
  

  tags = {
    Name = "k8s_private_rt"
  }
}  
#rt_subnet_association#
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.pub_sub.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.pri_sub.id
  route_table_id = aws_route_table.pri_rt.id
}
*/
#ssh key pair#
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_name
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem
  file_permission = "440"
}  
      
#k8s_worker instance#
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]#Canonical

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
 
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}
/*
data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = ["k8s_public_subnet"]
  }
}

data "aws_security_group" "sg" {
  filter {
    name   = "tag:Name"
    values = ["k8s_sg"]
  }
}
*/
resource "aws_instance" "k8s_worker" {
 ami = data.aws_ami.ubuntu.id
 instance_type = "t2.small"
 key_name      = var.key_name
 subnet_id = "subnet-09350ea21d25742e3"
 
    
tags = {
   Name = "k8s_worker"
 }

connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("${aws_key_pair.kp.key_name}.pem")
    host = self.public_ip
	
}
provisioner "remote-exec" {
    inline = [
	 "sudo apt update -y",
         "sudo apt install ansible -y"
]
  }

provisioner "file" {
    source = "kubernetes_join_command"
    destination = "/tmp/kubernetes_join_command"
  }

provisioner "file" {
    source = "k8s.yaml"
    destination = "/tmp/k8s.yaml"
  }

provisioner "remote-exec" {
   inline = [
    "sudo ansible-playbook /tmp/k8s.yaml"
]
  }
}  

/*
resource "null_resource" "file_creation" {
  provisioner "local-exec" {
     command = "/bin/bash file.sh"
  }	 
}
*/


