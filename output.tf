output "dev_ec2_public_ip" {
  value = aws_instance.dev_node.public_ip
}
