aws eks update-kubeconfig --region ap-south-1 --name gitops-eks
kubectl get nodes

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace

kubectl get pods -n argocd
kubectl get svc -n argocd

kubectl port-forward svc/argocd-server -n argocd 8081:443
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode

eksctl utils associate-iam-oidc-provider --region ap-south-1 --cluster gitops-eks --approve

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster gitops-eks \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region ap-south-1

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=gitops-eks \
  --set region=ap-south-1 \
  --set vpcId=<YOUR_VPC_ID> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

kubectl get pods -n kube-system | grep aws-load-balancer-controller

kubectl apply -f argo/application.yaml
kubectl get applications -n argocd

kubectl get ingress -n default

#### At last step ####

kubectl get ingress gitops-app-ingress

ADDRESS   <ALB-DNS-NAME>

http://<ALB-DNS-NAME>

Hello from GitOps + Terraform!!

