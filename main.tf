terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "gelios"

    workspaces {
      name = "terractions"
    }
  }
}
  
variable "docker_image" {
  type = string
}

provider "aws" {
  region                  = "eu-north-1"
}

# ssh-key for debug
resource "aws_key_pair" "terradocker" {
  key_name   = "terradocker"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9MDLWvCRoaIoiTDHvgobpMyGVhDKsvCTqlrBUIrqcNhSigXUi6T9ImW4eiPJDnCkx5mmGpEt7HU7PZD8sZOkMxOcRNAYrJxK57Tq4ifS355DerQTa0UFJtyh7cCaUGrGLyud0WJ1pJeDV9cgbXprgUbqbiMOjuTueEnM8Nc5YpODq+jTwOF9A/3wuvLptx6h+rVQsZAKqHyF/IJvPfvMUN2B8GIKNCoZTVhcCg+6PUkX4S6aFLu4xngbykYSl56WfjFQpiwlNTElzA+uRkkPzsjmhLrz76LJGDC/v/3TlODdzLwfM5gK6u+TJLp+LfiVtYvHusi5WdP99XAniPjmneQD9epmWggkphv+xJZVPgtohRjedph9/r4q2FfNmWPBui4S3jeu5AOoXnfyEbgPO/vGdxuVyJ8pWam/jDAKVtCcUhlHx/tUC3C4tdZ9n4BfQre5zx9KLSwM3yWsjamNyIsz6Dyj5eEHDhweUyCKyYeK+QQBzYorPKz/xugIwIOU= gelios@gelios"
}

resource "aws_instance" "web" {
  ami                    = "ami-0fbfc98b313840e86"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  key_name               = "terradocker"

  user_data = <<-EOT
                 #!/bin/sh
                 docker run -d -p 80:80 ${var.docker_image}
                 EOT

  tags = {
    Name = "DockerCV"
  }
}

resource "aws_eip" "CV" {
  instance = aws_instance.web.id
  vpc      = true
}

resource "aws_security_group" "web-sg" {
  name = "sgVC"
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

output "instance_ip_addr" {
  value = aws_eip.CV.public_ip
}
