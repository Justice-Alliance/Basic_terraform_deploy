# Creation d'un VPC
provider "aws" {
    region = var.region
}

resource "aws_vpc" "module_vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = true

    tags = {
        Name="Production-VPC"
    }
}

resource "aws_key_pair" "main" {
  key_name   = "admin_key"
  public_key = file(var.public_key_file)
}

# Creation des sous reseau publics

resource "aws_subnet" "module_public_subnet_1" {
    cidr_block = var.public_subnet_1_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}a"

    tags = {
        Name="Public-Subnet-1"        
    }
}

resource "aws_subnet" "module_public_subnet_2" {
    cidr_block = var.public_subnet_2_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}b"

    tags = {
        Name="Public-Subnet-2"        
    }
}

# Creation des sous reseaux prives 

resource "aws_subnet" "module_private_subnet_1" {
    cidr_block = var.private_subnet_1_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}a"

    tags = {
        Name="Private-Subnet-1"
    }
}

resource "aws_subnet" "module_private_subnet_2" {
    cidr_block = var.private_subnet_2_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}b"

    tags = {
        Name="Private-Subnet-2"
    }
}

# Creation des tables de routages pour les Routes publics

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.module_vpc.id
    tags = {
        Name="Public-Route-Table"
    }        
}

# Creation des tables de routage pour les routes privates

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.module_vpc.id
    tags = {
      Name="Private-Route-Table"   
    } 
}

# Association des routes publics/private avec les sous reseaux publics/private
resource "aws_route_table_association" "public_subnet_1_association" {
    route_table_id = aws_route_table.public_route_table.id
    subnet_id = aws_subnet.module_public_subnet_1.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
    route_table_id = aws_route_table.public_route_table.id
    subnet_id = aws_subnet.module_public_subnet_2.id 
}

resource "aws_route_table_association" "private_subnet_1_association" {
    route_table_id = aws_route_table.private_route_table.id
    subnet_id = aws_subnet.module_private_subnet_1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
    route_table_id = aws_route_table.private_route_table.id
    subnet_id = aws_subnet.module_private_subnet_2.id
}

# Creation d'un ELastic IP pour la passerelle NAT

resource "aws_eip" "elastic_ip_for_nat_gw" {
    vpc = true
    associate_with_private_ip = var.eip_association_address

    tags = {
        Name="Production-EIP"
    }   
}

# Creation d'une passerelle NAT et l'ajouter a la table de routage

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip_for_nat_gw.id
  subnet_id = aws_subnet.module_public_subnet_1.id

  tags = {
      Name="Production-NAT-GW"
  }
}

resource "aws_route" "nat_gateway_route" {
  route_table_id = aws_route_table.private_route_table.id
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"

}

# Creation d'une paserrelle internet et l'ajouter a la table de routage

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.module_vpc.id

    tags = {
        Name="Production-IGW"
    }
}

resource "aws_route" "igw_route" {
    route_table_id = aws_route_table.public_route_table.id
    gateway_id = aws_internet_gateway.internet_gateway.id
    destination_cidr_block = "0.0.0.0/0"
}

# Implementation d'une Instance EC2 -ubuntu

data "aws_ami" "ubuntu_latest" {
    owners = ["099720109477"]
    most_recent = true

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

resource "aws_instance" "ubuntu-ec2-instance-devops" {
    ami = data.aws_ami.ubuntu_latest.id
    instance_type = var.ec2_instance_type
    key_name = var.ec2_keypair
    security_groups = [aws_security_group.ec2-security-group.id]
    subnet_id = aws_subnet.module_public_subnet_1.id
    user_data =  "${file("cloud-config.yml")}"

}

resource "aws_security_group" "ec2-security-group" {
    name="EC2-Instance-SG"
    vpc_id = aws_vpc.module_vpc.id

    ingress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }  
}
