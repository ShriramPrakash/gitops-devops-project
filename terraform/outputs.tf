output "ec2_public_ip" {
  value = aws_instance.devops_vm.public_ip
}

output "ecr_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

