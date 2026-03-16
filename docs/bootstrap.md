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

#### Argo CD UI #####

1️⃣ Check if Argo CD Pods Are Running
First confirm Argo CD is installed correctly.


kubectl get pods -n argocd
You should see pods like:

argocd-server
argocd-repo-server
argocd-application-controller
argocd-dex-server


2️⃣ Check the Argo CD Service
Run:

kubectl get svc -n argocd
Typical output:

argocd-server   ClusterIP   10.x.x.x   <none>   443/TCP
If it shows ClusterIP, it means it is only accessible inside the cluster.


3️⃣ Access Method 1 — Port Forward (Most Common for Testing)
Run:

kubectl port-forward svc/argocd-server -n argocd 8080:443
Then open your browser:

https://localhost:8080
Ignore the SSL warning.


4️⃣ Get Argo CD Admin Password
Run:

kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
Username:

admin
Password:

<decoded password>
<img width="792" height="1049" alt="image" src="https://github.com/user-attachments/assets/07374e11-b5ab-4f4f-83e2-b79d0f0a2f6f" />


Below are only the remaining commands you should run manually, with explanation and purpose.

1️⃣ Access Argo CD UI (Port Forward)
kubectl port-forward svc/argocd-server -n argocd 8081:443
What it does

Creates a temporary tunnel from your machine → Kubernetes service.

Flow:

Browser
 |
localhost:8081
 |
kubectl port-forward
 |
argocd-server service
 |
Argo CD UI

Open browser:

https://localhost:8081
2️⃣ Get Argo CD Admin Password
kubectl get secret argocd-initial-admin-secret \
-n argocd \
-o jsonpath="{.data.password}" | base64 --decode
What it does

Argo CD stores the default password inside a Kubernetes Secret.

This command:

Retrieves the secret

Decodes the Base64 value

Login credentials:

Username: admin
Password: <decoded password>
3️⃣ Enable IAM OIDC Provider
eksctl utils associate-iam-oidc-provider \
--region ap-south-1 \
--cluster gitops-eks \
--approve
Why needed

This enables IRSA (IAM Roles for Service Accounts).

This allows Kubernetes pods to assume IAM roles securely.

Example:

AWS Load Balancer Controller

needs AWS permissions to create:

ALB

Target Groups

Security Groups

4️⃣ Download ALB Controller IAM Policy
curl -o iam_policy.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
What it does

Downloads the required IAM permissions for the controller.

Permissions include:

elasticloadbalancing:CreateLoadBalancer
elasticloadbalancing:CreateTargetGroup
ec2:AuthorizeSecurityGroupIngress
5️⃣ Create IAM Policy in AWS
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://iam_policy.json
What it does

Creates a custom IAM policy in AWS.

This policy will later be attached to the Kubernetes controller.

6️⃣ Create IAM Service Account
eksctl create iamserviceaccount \
  --cluster gitops-eks \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region ap-south-1
What it does

Creates:

Kubernetes ServiceAccount
+
IAM Role
+
Attached IAM Policy

This enables the controller pod to call AWS APIs securely.

7️⃣ Install AWS Load Balancer Controller

Add Helm repo:

helm repo add eks https://aws.github.io/eks-charts
helm repo update

Install controller:

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=gitops-eks \
  --set region=ap-south-1 \
  --set vpcId=<YOUR_VPC_ID> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
What it does

Installs the AWS Load Balancer Controller inside the cluster.

Purpose:

Automatically create Application Load Balancers (ALB) from Kubernetes Ingress.

Flow:

Ingress resource
 |
AWS Load Balancer Controller
 |
AWS API
 |
ALB created
8️⃣ Verify Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

Expected output:

aws-load-balancer-controller Running
9️⃣ Register Argo CD Application
kubectl apply -f argo/application.yaml
What it does

Creates an Argo CD Application resource.

This tells Argo CD:

Watch this Git repository
Deploy application manifests
🔟 Verify Argo CD Application
kubectl get applications -n argocd

Expected output:

gitops-app Synced Healthy
1️⃣1️⃣ Check Kubernetes Ingress
kubectl get ingress -n default

This shows the Ingress resource created by your Helm chart.

1️⃣2️⃣ Get Application URL
kubectl get ingress gitops-app-ingress

Example output:

ADDRESS
k8s-gitops-123456.ap-south-1.elb.amazonaws.com
1️⃣3️⃣ Access Application

Open browser:

http://<ALB-DNS>

Expected result:

Hello from GitOps + Terraform!!
Final Bootstrap Steps (After infra.yaml)
1 Access Argo CD UI
2 Get Argo CD admin password
3 Enable IAM OIDC provider
4 Download ALB controller IAM policy
5 Create IAM policy
6 Create IAM service account
7 Install AWS Load Balancer Controller
8 Verify controller
9 Register Argo CD application
10 Verify application
11 Check ingress
12 Get ALB DNS
13 Access application


Command to enable OIDC for EKS
eksctl utils associate-iam-oidc-provider \
  --cluster <cluster-name> \
  --region <region> \
  --approve

Example:

eksctl utils associate-iam-oidc-provider \
  --cluster my-eks-cluster \
  --region us-east-1 \
  --approve
2️⃣ What this command does

This command:

1️⃣ Finds the OIDC issuer URL of the Amazon EKS cluster

2️⃣ Creates an OIDC identity provider in IAM

3️⃣ Allows Kubernetes service accounts to assume IAM roles

Result:

IAM OIDC Provider Created
↓
Cluster Service Accounts can assume IAM roles
↓
IRSA enabled
3️⃣ Verify OIDC provider

You can check it with:

aws iam list-open-id-connect-providers

You’ll see something like:

arn:aws:iam::123456789012:oidc-provider/
oidc.eks.us-east-1.amazonaws.com/id/ABCDE12345
4️⃣ Get OIDC issuer URL of cluster
aws eks describe-cluster \
  --name my-eks-cluster \
  --query "cluster.identity.oidc.issuer" \
  --output text

Example output:

https://oidc.eks.us-east-1.amazonaws.com/id/ABCDE12345
5️⃣ What happens after OIDC is enabled

Now you can create:

IAM Role
↓
Trust policy with OIDC provider
↓
Attach policy
↓
Bind role to Kubernetes ServiceAccount

This is how components like the AWS Load Balancer Controller get permissions.

6️⃣ Short interview explanation

You can say:

We enable OIDC in EKS using the eksctl utils associate-iam-oidc-provider command. This creates an IAM OIDC provider that allows Kubernetes service accounts to assume IAM roles using IRSA.

✅ If you'd like, I can also show you the full command used to create the IAM Service Account for the AWS Load Balancer Controller (very common in EKS projects).

n my project i have one ingress and i am able access both using this kubectl port-forward svc/argocd-server -n argocd 8080:443 Then open your browser:

https://localhost:8080

Good observation — what you’re seeing actually involves two different access methods. Let’s separate them clearly.

You said you can access ArgoCD using:

kubectl port-forward svc/argocd-server -n argocd 8080:443

and then open:

https://localhost:8080

That does NOT use your Ingress or ALB at all. It directly tunnels traffic from your laptop to the ArgoCD service.

Let’s break it down.

1️⃣ What kubectl port-forward does

When you run:

kubectl port-forward svc/argocd-server -n argocd 8080:443

Kubernetes creates a temporary tunnel.

Traffic flow becomes:

Browser
   │
   ▼
localhost:8080
   │
   ▼
kubectl port-forward tunnel
   │
   ▼
argocd-server service (port 443)
   │
   ▼
ArgoCD UI pod

So you're bypassing the Ingress completely.

2️⃣ Why this works even without Ingress

The argocd-server service already exists inside the cluster.

Example:

kubectl get svc -n argocd

You will see something like:

argocd-server   ClusterIP   10.x.x.x   443/TCP

ClusterIP means:

Accessible only inside Kubernetes cluster

kubectl port-forward lets your laptop temporarily act like it is inside the cluster network.

3️⃣ Where your Ingress is used

Your Helm template creates Ingress only for your application, not ArgoCD.

Your Ingress routes traffic like this:

Internet
   │
   ▼
ALB
   │
   ▼
Ingress
   │
   ▼
Application Service
   │
   ▼
Application Pods

That is how users access the deployed application.

4️⃣ Why ArgoCD UI uses port-forward in many projects

Many teams do not expose ArgoCD publicly for security reasons.

So they access it using:

kubectl port-forward

instead of creating an ALB or public endpoint.

5️⃣ Your project likely looks like this
Developer
   │
   ▼
Git Repository
   │
   ▼
ArgoCD
   │
   ▼
EKS Cluster
   │
   ├── Application Ingress → ALB → Users
   │
   └── ArgoCD Server
          ↑
          │
   kubectl port-forward
          │
       Developer browser
6️⃣ Simple explanation you can give in interviews

You can say:

In our project ArgoCD is not exposed through the load balancer. We access the ArgoCD UI using kubectl port-forward, which creates a secure tunnel from the local machine to the argocd-server service inside the Kubernetes cluster. The application itself is exposed through an Ingress that creates an AWS Application Load Balancer.

7️⃣ Quick way to remember
kubectl port-forward → temporary local tunnel
Ingress + ALB → external user traffic

💡 One important follow-up question interviewers often ask after this is:

“If ArgoCD is inside the cluster, how does it deploy applications to Kubernetes?”

The answer involves:

Application CR
↓
Application Controller
↓
Repo Server
↓
kubectl apply

If you want, I can walk you through that full ArgoCD internal flow as well.
