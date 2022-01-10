variable "docker_image" {
  type = string
  description = "Docker image name"
  default = "docker:image"
}

#variable "aws_key_id" {
#  type = string
#  description = "AWS Key ID"
#  default = "ki"
#}
#
#variable "aws_secret_key" {
#  type = string
#  description = "AWS Secret Key"
#  default = "sk"
#}

variable "aws_region" {
  type = string
  description = "AWS Default Region"
  default = "dr"
}

variable "aws_format" {
  type = string
  description = "AWS Format"
  default = "json"
}

variable "aws_cert_bucket" {
  type = string
  description = "Storage"
  default = "cb"
}

variable "aws_cert_bucket_arn" {
  type = string
  description = "Certificate storage"
  default = "cba"
}
