#!/bin/sh

#Copy certificate from S3 bucket
aws s3 cp s3://${var.aws_cert_bucket} /home/ec2-user/ssl --recursive

#Run container
docker run -d -p 80:80 -p 443:443 --mount type=bind,source=/home/ec2-user/ssl,target=/ssl ${var.docker_image}
