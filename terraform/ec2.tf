resource "aws_instance" "gitops_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.gitops_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # -----------------------------
    # 1. System update
    # -----------------------------
    yum update -y

    # -----------------------------
    # 2. Install Docker
    # -----------------------------
    yum install -y docker git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # -----------------------------
    # 3. Install kubectl
    # -----------------------------
    curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # -----------------------------
    # 4. Install kind
    # -----------------------------
    curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
    chmod +x /usr/local/bin/kind

    # -----------------------------
    # 5. Install Helm
    # -----------------------------
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # -----------------------------
    # 6. Switch to ec2-user and setup k8s
    # -----------------------------
    su - ec2-user << 'EOS'

    kind create cluster --name gitops

    kubectl create namespace argocd || true

    kubectl apply -n argocd \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    EOS
EOF

  tags = {
    Name = "gitops-control-plane"
  }
}

