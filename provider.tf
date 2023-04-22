terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.62.0"
    }
  }
}

provider "aws" {
  access_key = "AKIAQP355FGK5RNQZIEF"
  secret_key = "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"
  region     = "us-east-2"

}

resource "aws_vpc" "maniche" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Production-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.maniche.id

  tags = {
    Name = "prod-igw"
  }
}

resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.maniche.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  

  tags = {
    Name = "prod-rt"
  }
}

resource "aws_subnet" "pub-subnet" {
  vpc_id     = aws_vpc.maniche.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "pub-subnet"
  }
}

resource "aws_route_table_association" "pub-subnet" {
  subnet_id      = aws_subnet.pub-subnet.id
  route_table_id = aws_route_table.prod-rt.id
}

resource "aws_security_group" "pub-subnet" {
  name        = "allow_web-traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.maniche.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow-web-traffic"
  }
}

resource "aws_network_interface" "webserver-nacl" {
  subnet_id       = aws_subnet.pub-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.pub-subnet.id]
}

resource "aws_eip" "pub-subnet" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver-nacl.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_instance" "wed-server" {
  ami           = "ami-0a695f0d95cefc163" 
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.webserver-nacl.id
  }

  user_data= <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo systemctl enable apache2
  sudo bash -c 'echo your very first terraform deploment of ubuntu webserver >
  /var/www/html/index.html
  EOF
}





 

