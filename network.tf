resource "aws_eip" "CV" {
  instance = aws_instance.CV_instance.id
  vpc      = true

  tags = {
    Name = "CV"
  }
}

resource "aws_vpc" "CV_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "CV_vpc"
  }
}

resource "aws_subnet" "CV_subnet" {
  vpc_id            = aws_vpc.CV_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "CV_subnet"
  }
}

resource "aws_route_table" "CV_rt" {
  vpc_id = aws_vpc.CV_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.CV_gw.id
  }

  tags = {
    Name = "CV_rt"
  }
}

resource "aws_route_table_association" "CV_rta" {
  subnet_id      = aws_subnet.CV_subnet.id
  route_table_id = aws_route_table.CV_rt.id
}

resource "aws_internet_gateway" "CV_gw" {
  vpc_id = aws_vpc.CV_vpc.id

  tags = {
    Name = "CV_gw"
  }
}

resource "aws_network_interface" "CV_eni" {
  subnet_id       = aws_subnet.CV_subnet.id
  security_groups = [aws_security_group.CV_sg.id]
  private_ips     = ["10.0.0.10"]

  tags = {
    Name = "CV_eni"
  }
}

locals {
  ingress_rules = [{
    port        = 443
    description = "Ingress rule for port 443"
    },
    {
      port        = 80
      description = "Ingree rule for port 80"
    },
    {
      port        = 22
      description = "Ingree rule for port 22"
    }
  ]
}

resource "aws_security_group" "CV_sg" {
  name   = "CV_sg"
  vpc_id = aws_vpc.CV_vpc.id

  dynamic "ingress" {
    for_each = local.ingress_rules

    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_route53_record" "main" {
  zone_id = "Z040603910U6C3CYA7VRW"
  name    = "predybalov.link"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.CV.public_ip]
}

resource "aws_route53_record" "www" {
  zone_id = "Z040603910U6C3CYA7VRW"
  name    = "www.predybalov.link"
  type    = "A"

  alias {
    name                   = aws_route53_record.main.name
    zone_id                = "Z040603910U6C3CYA7VRW"
    evaluate_target_health = true
  }
}
