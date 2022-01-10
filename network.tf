resource "aws_eip" "CV" {
  instance = aws_instance.web.id
  vpc      = true
}

resource "aws_security_group" "web-sg" {
  name = "sgCV"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
