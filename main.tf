terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }

  cloud {
    organization = "gelios"

    workspaces {
      name = "CV"
    }
  }
}
  
provider "aws" {
  region = "eu-north-1"
}

# ssh-key for debug
resource "aws_key_pair" "terradocker" {
  key_name   = "terradocker"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9MDLWvCRoaIoiTDHvgobpMyGVhDKsvCTqlrBUIrqcNhSigXUi6T9ImW4eiPJDnCkx5mmGpEt7HU7PZD8sZOkMxOcRNAYrJxK57Tq4ifS355DerQTa0UFJtyh7cCaUGrGLyud0WJ1pJeDV9cgbXprgUbqbiMOjuTueEnM8Nc5YpODq+jTwOF9A/3wuvLptx6h+rVQsZAKqHyF/IJvPfvMUN2B8GIKNCoZTVhcCg+6PUkX4S6aFLu4xngbykYSl56WfjFQpiwlNTElzA+uRkkPzsjmhLrz76LJGDC/v/3TlODdzLwfM5gK6u+TJLp+LfiVtYvHusi5WdP99XAniPjmneQD9epmWggkphv+xJZVPgtohRjedph9/r4q2FfNmWPBui4S3jeu5AOoXnfyEbgPO/vGdxuVyJ8pWam/jDAKVtCcUhlHx/tUC3C4tdZ9n4BfQre5zx9KLSwM3yWsjamNyIsz6Dyj5eEHDhweUyCKyYeK+QQBzYorPKz/xugIwIOU= gelios@gelios"
}


data "aws_iam_policy_document" "CV_instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "CV_instance_role" {
  name               = "CV_instance_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.CV_instance_assume_role.json
}


data "aws_iam_policy_document" "S3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.aws_cert_bucket}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.aws_cert_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "S3_cert_policy" {
  name   = "S3_cert_policy"
  policy = data.aws_iam_policy_document.S3.json
}


resource "aws_iam_role_policy_attachment" "S3_attach" {
  role       = aws_iam_role.CV_instance_role.name
  policy_arn = aws_iam_policy.S3_cert_policy.arn
}

resource "aws_iam_instance_profile" "CV_profile" {
  name = "CV_profile"
  role = aws_iam_role.CV_instance_role.name
}

resource "aws_instance" "web" {
  ami                    = "ami-0fbfc98b313840e86"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.CV_profile.name
  key_name               = "terradocker"

  user_data = <<-EOT
                 #!/bin/sh
                 aws s3 cp s3://${var.aws_cert_bucket} /home/ec2-user/ssl --recursive
                 docker run -d -p 80:80 -p 443:443 --mount type=bind,source=/home/ec2-user/ssl,target=/ssl ${var.docker_image}
                 EOT

  tags = {
    Name = "CV"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}
