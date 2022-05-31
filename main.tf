erraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Creation d'un VPC
provider "aws" {
    region = var.region
    access_key = "AKIAQ2HXPMTCJZRJT4UG"
    secret_key = "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"
}

 resource "random_pet" "stack_name" {
   length    = 5
   separator = "-"
   prefix    = "artifactory"
 }
resource "aws_vpc" "module_vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = random_pet.stack_name.id
    }
}

resource "tls_private_key" "pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${random_pet.stack_name.id}-key"
  public_key = "${tls_private_key.pair.public_key_openssh}"
}

# Creation des sous reseau publics

resource "aws_subnet" "module_public_subnet_1" {
    cidr_block = var.public_subnet_1_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}a"
    tags = {
      Name = random_pet.stack_name.id
    }
}

/* resource "aws_subnet" "module_public_subnet_2" {
    cidr_block = var.public_subnet_2_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}b"

    tags = {
        Name="Public-Subnet-2"        
    }
} */

# Creation des sous reseaux prives 

resource "aws_subnet" "module_private_subnet_1" {
    cidr_block = var.private_subnet_1_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}a"

    tags = {
      Name = random_pet.stack_name.id
    }
    
}

/* resource "aws_subnet" "module_private_subnet_2" {
    cidr_block = var.private_subnet_2_cidr
    vpc_id = aws_vpc.module_vpc.id
    availability_zone = "${var.region}b"

    tags = {
        Name="Private-Subnet-2"
    }
}  */

# Creation des tables de routages pour les Routes publics
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.module_vpc.id
    tags = {
        Name = random_pet.stack_name.id
    }        
}

# Creation des tables de routage pour les routes privates
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.module_vpc.id
    tags = {
      Name = random_pet.stack_name.id
    }
}

# Association des routes publics/private avec les sous reseaux publics/private
resource "aws_route_table_association" "public_subnet_1_association" {
    route_table_id = aws_route_table.public_route_table.id
    subnet_id = aws_subnet.module_public_subnet_1.id
}

/* resource "aws_route_table_association" "public_subnet_2_association" {
    route_table_id = aws_route_table.public_route_table.id
    subnet_id = aws_subnet.module_public_subnet_2.id 
}
 */
resource "aws_route_table_association" "private_subnet_1_association" {
    route_table_id = aws_route_table.private_route_table.id
    subnet_id = aws_subnet.module_private_subnet_1.id
}

/* resource "aws_route_table_association" "private_subnet_2_association" {
    route_table_id = aws_route_table.private_route_table.id
    subnet_id = aws_subnet.module_private_subnet_2.id
} */

# Creation d'un ELastic IP pour la passerelle NAT

resource "aws_eip" "elastic_ip_for_nat_gw" {
    vpc = true
    associate_with_private_ip = var.eip_association_address
    tags = {
      Name = random_pet.stack_name.id
    } 
}

# Creation d'une passerelle NAT et l'ajouter a la table de routage

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip_for_nat_gw.id
  subnet_id = aws_subnet.module_private_subnet_1.id
  tags = {
    Name = random_pet.stack_name.id
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
      Name = random_pet.stack_name.id
    }
}

/* resource "aws_route" "igw_route" {
    route_table_id = aws_route_table.private_route_table.id
    gateway_id = aws_internet_gateway.internet_gateway.id
    destination_cidr_block = "0.0.0.0/0"
} */

# Implementation d'une Instance EC2 -ubuntu

data "aws_ami" "ubuntu_latest" {
    owners = ["099720109477"]
    most_recent = true

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

resource "aws_security_group" "egress" {
    name = "${random_pet.stack_name.id}-egress"
    vpc_id = aws_vpc.module_vpc.id

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }  
}

resource "aws_security_group" "ingress_ssh" {
  name        = "${random_pet.stack_name.id}-ingress-ssh"
  description = "Allow incoming SSH traffic (TCP/22)"
  vpc_id        = aws_vpc.module_vpc.id
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }
}

resource "aws_security_group" "public_in_http" {
  name        = "${random_pet.stack_name.id}-ingress-http"
  description = "Allow incoming Web traffic (TCP/80)"
  vpc_id        = aws_vpc.module_vpc.id
  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  
 }

}

resource "aws_security_group" "public_in_https" {
  name        = "${random_pet.stack_name.id}-ingress-https"
  description = "Allow incoming Web secure traffic (TCP/443)"
  vpc_id        = aws_vpc.module_vpc.id
  ingress {
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  
  }
}   
resource "aws_instance" "ubuntu-ec2-instance-devops" {
    ami = data.aws_ami.ubuntu_latest.id
    instance_type = var.ec2_instance_type
    key_name = aws_key_pair.generated_key.key_name
    security_groups = [aws_security_group.egress.id, 
                       aws_security_group.ingress_ssh.id, 
                       aws_security_group.public_in_http.id, 
                       aws_security_group.public_in_https.id]
    subnet_id = aws_subnet.module_private_subnet_1.id
    user_data =  file("init-script.sh")
    associate_public_ip_address = true
    tags = {
      Name = random_pet.stack_name.id
    }
}

resource "aws_elb" "instance-devops" {
  availability_zones = "ca-central-1a"
  name = "${random_pet.stack_name.id}-elb"
  subnets         = [aws_subnet.module_private_subnet_1, aws_subnet.module_public_subnet_1]
  security_groups = [aws_security_group.egress.id, 
                       aws_security_group.ingress_ssh.id, 
                       aws_security_group.public_in_http.id, 
                       aws_security_group.public_in_https.id]
  internal        = false
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = [aws_instance.fooubuntu-ec2-instance-devops.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

}


resource "aws_launch_configuration" "launch-config-1" {
  name = "${random_pet.stack_name.id}-alc"
  image_id = "${var.ami_image_id}"
  instance_type = "t3.medium"
  security_groups = [aws_security_group.egress.id, 
                       aws_security_group.ingress_ssh.id, 
                       aws_security_group.public_in_http.id, 
                       aws_security_group.public_in_https.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "auto-scaling-group-01" {
  name = "${random_pet.stack_name.id}-asg"
  launch_configuration = "${aws_launch_configuration.launch-config-1.id}"
  availability_zones = "ca-central-1a"
  load_balancers = ["${aws_elb.instance-devops.name}"]
  health_check_type = "ELB"
  min_size = "${var.ec2_instance_min_size}"
  max_size = "${var.ec2_instance_max_size}"
}

resource "aws_elb" "test-elb" {
  name = "${random_pet.stack_name.id}-asg"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.test-security-group-1.id}"]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.web_server_port}/"
  }
}
resource "aws_autoscaling_policy" "scale-up" {
    name = "EU-WEST-TEST-ASP-UP-01"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.test-auto-scaling-group-01.name}"
}

resource "aws_autoscaling_policy" "scale-down" {
    name = "EU-WEST-TEST-ASP-DOWN-01"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.test-auto-scaling-group-01.name}"
}

resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "EU-WEST-TEST-CWMA-MEM-HIGH-01"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.scale-up.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.test-auto-scaling-group-01.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "EU-WEST-TEST-CWMA-MEM-LOW-01"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.scale-down.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.test-auto-scaling-group-01.name}"
    }
}

