terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc-openstack" {
  cidr_block       = "172.16.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-openstack"
  }
}

resource "aws_internet_gateway" "igw-openstack" {
  vpc_id = aws_vpc.vpc-openstack.id
  tags = {
    Name = "igw-openstack"
  }
  depends_on = [ aws_vpc.vpc-openstack ]
}

resource "aws_subnet" "openstack-subnet" {
  vpc_id     = aws_vpc.vpc-openstack.id
  cidr_block = "172.16.0.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "openstack-subnet"
  }
  depends_on = [ aws_vpc.vpc-openstack ]
}

resource "aws_route_table" "openstack-rt" {
  vpc_id = aws_vpc.vpc-openstack.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-openstack.id
  }
  depends_on = [ aws_internet_gateway.igw-openstack ] 
}

resource "aws_route_table_association" "rtassociate" {
  subnet_id      = aws_subnet.openstack-subnet.id
  route_table_id = aws_route_table.openstack-rt.id
  depends_on = [ aws_route_table.openstack-rt ]
}

resource "aws_security_group" "openstack-sg-allowall" {
  name        = "openstack-sg-allowall"
  vpc_id      = aws_vpc.vpc-openstack.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openstack-sg-allowall"
  }
  depends_on = [ aws_subnet.openstack-subnet ]
}

resource "aws_instance" "openstack" {
  ami           = "ami-0f8ce9c417115413d"  ## ubuntu server 20.04 Milan region
  instance_type = "c5.4xlarge"
  subnet_id = aws_subnet.openstack-subnet.id
  key_name = "OSscriptKey"  ##remember to change the key with your own one
  vpc_security_group_ids = [ aws_security_group.openstack-sg-allowall.id ]
  root_block_device {
    volume_size = 300 
  }
  tags = {
    Name = "OpenStack Instance"
  }
  
  ##script start
  provisioner "file" {
    source      = "C:\\Users\\lzeccardo\\Documents\\CaseStudy_Cloud\\terraform\\openstackinstance\\OpStInstallScript.sh"  ##double \ is needed only if source system of the file is windows
    destination = "/tmp/OpStInstallScript.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sed -i -e 's/\r$//' /tmp/OpStInstallScript.sh",  ##only needed if you are terraforming on windows
      "chmod +x /tmp/OpStInstallScript.sh",
      "sudo /tmp/OpStInstallScript.sh",
    ]
  }
    
  # Login to the ubuntu with the aws key (PEM format)
  connection {
    type        = "ssh"
    user        = "ubuntu"   ##default user for ubuntu server in AWS
    password    = ""
    private_key = file(var.keyPath)
    host        = self.public_ip
  }
##script end

  depends_on = [aws_subnet.openstack-subnet ]
}