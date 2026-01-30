output "ec2_public_ip" {
  value = aws_instance.gitops_ec2.public_ip
}
