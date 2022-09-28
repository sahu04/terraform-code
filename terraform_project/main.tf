
provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAUWXUAJTMJ4XASA5Z"
  secret_key = "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"
 }

#create VPC
resource "aws_vpc" "prod-VPC" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}
#create internetgetway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-VPC.id

  tags = {
    Name = "prod-gw"
  }
}
#create custome route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             =  aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-route"
  }
}
#create a subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "prod-Subnet"
  }
}

# associate subnet wit route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
#create security group allow to port 22,80,443
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow web_traffic"
  vpc_id      = aws_vpc.prod-VPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 447
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "HTTPS"
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
    Name = "allow_web_traffic"
  }
}
# create network interface wit an ip in te subnet tat was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]

}
#assign an elastic ip to te network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on  = [aws_internet_gateway.gw]
}


# create ubuntu server and install /emable apace2
resource "aws_instance" "web_server_instance" {
 ami =  "ami-0d8633ffb1a5574db"
 instance_type = "t2.micro"
 availability_zone = "ap-south-1a"
 key_name = "main -key"
 network_interface {
   device_index = 0
   network_interface_id = aws_network_interface.web-server-nic.id
 }

user_data = <<EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y && sudo systemctl start apache2
                 "echo your very first web server > /var/www/html/index.html"
EOF

   tags = {
     Name = "web-server"
   }
 }
