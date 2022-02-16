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

resource "aws_key_pair" "CV_env" {
  key_name   = "CV_env"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwh8BWW2nBQDcI2jPYNaP1rIAZZpbGGaO/WR3XEv7PI CV_env"
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

resource "aws_instance" "CV_instance" {
  ami           = "ami-0fbfc98b313840e86"
  instance_type = "t3.micro"
  network_interface {
    network_interface_id = aws_network_interface.CV_eni.id
    device_index         = 0
  }
  iam_instance_profile = aws_iam_instance_profile.CV_profile.name
  key_name             = "CV_env"

  user_data = file("user-data.sh")

  tags = {
    Name = "CV"
  }

  lifecycle {
    create_before_destroy = true
  }
}
