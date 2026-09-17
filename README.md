# EKS Nginx Demo

Terraform provisions an EKS cluster on AWS, and Nginx is deployed on it with 2 replicas.

**Note on LoadBalancer:** the Service is written as `type: LoadBalancer`, but this AWS account has a restriction that blocks ELB creation (`OperationNotPermitted: This AWS account currently does not support creating load balancers`). So for the actual demo, I switched the Service to `NodePort` and used `kubectl port-forward` from a public EC2 box to expose it. Everything else (cluster, node group, deployment, replicas) is exactly what the assignment asks for — only the external-access step had to be worked around. Details below.

## Architecture

**As designed:**
```
Internet → AWS Network Load Balancer → Service (LoadBalancer) → Nginx Pods (x2) → EKS worker nodes (private subnets)
```

**As actually demoed (due to the ELB restriction above):**
```
Browser → EC2 public IP:8080 → kubectl port-forward → Service (NodePort :30080) → Nginx Pods (x2) → EKS worker nodes (private subnets)
```

## Repo structure

```
eks-nginx-demo/
├── README.md
├── terraform/
│   ├── main.tf        
│   ├── eks.tf          
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
└── kubernetes/
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

## Infra details

- Region: `ap-south-1`, AZs: `ap-south-1a` / `ap-south-1b`
- VPC: `10.0.0.0/16` — public subnets `10.0.101.0/24`, `10.0.102.0/24`, private subnets `10.0.1.0/24`, `10.0.2.0/24`
- NAT gateway for outbound internet from the private subnets
- EKS cluster `nginx-demo-eks`, Kubernetes `1.36`
- Managed node group: `t3.small` (switched from `t3.medium` — not free-tier eligible on this account), desired 2 / min 1 / max 3, worker nodes in the private subnets

## Prerequisites

- Terraform >= 1.5.0, AWS CLI v2, kubectl, Git
- AWS credentials configured (`aws configure`) — no keys are hardcoded anywhere in this repo
- Check you're authenticated: `aws sts get-caller-identity`

## Deploy

```bash
git clone https://github.com/aditya8112soni-cr/eks-nginx-demo.git
cd eks-nginx-demo/terraform

terraform init
terraform plan
terraform apply  
```

Point kubectl at the new cluster:
```bash
aws eks update-kubeconfig --region ap-south-1 --name nginx-demo-eks
kubectl get nodes 
```

Deploy Nginx:
```bash
cd ../kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

## Validate

```bash
kubectl get deployment -n nginx-demo   
kubectl get pods -n nginx-demo       
kubectl get svc -n nginx-demo      
kubectl get endpoints nginx-service -n nginx-demo
```

Self-healing check — delete a pod and confirm it comes back:
```bash
kubectl delete pod <pod-name> -n nginx-demo
kubectl get pods -n nginx-demo
```

## Accessing it externally (NodePort workaround)

Worker nodes are in private subnets, so from a public EC2 instance:
```bash
kubectl port-forward -n nginx-demo svc/nginx-service 8080:80 --address 0.0.0.0
```
Then hit `http://<EC2-public-ip>:8080` — you should see "Welcome to nginx!". EC2 security group only allows port `8080` from my IP. Note `port-forward` has to stay running for this to keep working — it's a testing shortcut, not how you'd expose this for real.

If the account restriction gets lifted later, switching `service.yaml` back to `type: LoadBalancer` and re-applying is all that's needed — the public subnets are already tagged correctly for it.

## Troubleshooting

- **Pods stuck Pending** → `kubectl describe pod <name> -n nginx-demo`, `kubectl get events -n nginx-demo`
- **Service has no endpoints** → check pod labels match the service selector (`app=nginx`)
- **EXTERNAL-IP stuck pending** → likely the same ELB account restriction mentioned above; use the NodePort + port-forward path instead
- **kubectl says Unauthorized** → re-run `aws eks update-kubeconfig ...` and check `aws sts get-caller-identity`

## Cleanup

```bash
cd kubernetes
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f namespace.yaml

cd ../terraform
terraform destroy
```

## Notes

- No AWS credentials or `.tfstate` committed — see `.gitignore`
- For production I'd restrict the EKS public endpoint, use per-AZ NAT gateways instead of one shared one, and move state to a remote backend (S3 + lock table)