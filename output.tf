output "instance_ip_addr" {
  value = aws_eip.CV.public_ip
}
