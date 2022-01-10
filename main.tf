terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }
#  required_version = ">= 1.1.0"

  cloud {
    organization = "gelios"

    workspaces {
      name = "terractions"
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


data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "instance_role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}


data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::gelios-cv"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::gelios-cv/*"
    ]
  }
}

resource "aws_iam_policy" "policydocument" {
  name   = "tf-policydocument"
  policy = data.aws_iam_policy_document.example.json
}


resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.policydocument.arn
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.instance.name
}

resource "aws_instance" "web" {
  ami                    = "ami-0fbfc98b313840e86"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  iam_instance_profile   = "${aws_iam_instance_profile.test_profile.name}"
  key_name               = "terradocker"

  user_data = <<-EOT
                 #!/bin/sh
                 aws s3 cp ${var.aws_cert_bucket} /home/ec2-user/ssl --recursive
                 docker run -d -p 80:80 -p 443:443 --mount type=bind,source=/home/ec2-user/ssl,target=/ssl ${var.docker_image}
                 EOT

  tags = {
    Name = "DockerCV"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}
