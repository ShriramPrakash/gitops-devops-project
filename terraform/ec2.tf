############################################
# AMI Lookup (Dynamic, Region-Aware)
############################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################################
# EC2 Instance for GitOps Control Plane
############################################
resource "aws_instance" "gitops_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.gitops_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # System update
    yum update -y

    # Install Docker & Git
    yum install -y docker git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # Install kubectl
    curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Install KIND
    curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
    chmod +x /usr/local/bin/kind

    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Switch to ec2-user for Kubernetes tools
    su - ec2-user << 'EOS'
      newgrp docker
      kind create cluster --name gitops

      kubectl create namespace argocd || true
      kubectl apply -n argocd \
        -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

      # -----------------------------
      # APPLY ARGO CD APPLICATION (GitOps bootstrap)
      # -----------------------------
      kubectl apply -f https://raw.githubusercontent.com/ShriramPrakash/gitops-devops-project/main/argo/application.yaml

      # -----------------------------
      # WAIT for Argo CD to be ready
      # -----------------------------
      kubectl wait deployment argocd-server \
        -n argocd --for=condition=Available=True --timeout=300s

      # -----------------------------
      # Expose Argo CD UI (NodePort)
      # -----------------------------
      cat << 'EOF2' | kubectl apply -f -
      apiVersion: v1
      kind: Service
      metadata:
        name: argocd-server-nodeport
        namespace: argocd
      spec:
        type: NodePort
        selector:
          app.kubernetes.io/name: argocd-server
        ports:
          - port: 443
            targetPort: 8080
            nodePort: 30081
      EOF2

    EOS
  EOF

  tags = {
    Name = "gitops-control-plane"
  }
}
