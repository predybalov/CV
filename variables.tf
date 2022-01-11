variable "docker_image" {
  type = string
  description = "Docker image name"
  default = "docker:image"
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
