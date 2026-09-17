# EKS Nginx Demo

A demo AWS EKS environment provisioned using Terraform and running a simple Nginx application on Kubernetes.

## Objective

The objective of this project is to:

* Provision an Amazon EKS cluster using Terraform.
* Create the required AWS networking infrastructure.
* Create EKS worker nodes/node groups.
* Deploy Nginx with at least 2 replicas.
* Expose Nginx using a Kubernetes Service.
* Verify that the Nginx Pods are scheduled and running.
* Make the Nginx application externally accessible.
* Verify the Nginx default page.
* Validate that the infrastructure can be recreated using Terraform.
* Maintain the complete implementation in GitHub.

> **AWS Account Limitation:** The Kubernetes `LoadBalancer` Service was tested, but the AWS account currently has an account-level restriction that prevents Elastic Load Balancer creation. Therefore, the working external-access demonstration uses a `NodePort` Service and `kubectl port-forward` through a public EC2 administration machine.

---

## Architecture

### Intended Architecture

```text
                         Internet
                            |
                            v
                 AWS Network Load Balancer
                       Public Subnets
                            |
                            v
              Kubernetes Service
               type: LoadBalancer
                            |
                 +----------+----------+
                 |                     |
                 v                     v
            Nginx Pod 1           Nginx Pod 2
                 |                     |
                 +----------+----------+
                            |
                            v
                    EKS Worker Nodes
                    Private Subnets
                            |
                            v
                         AWS VPC
```

### Working Architecture Used for Validation

```text
                         Internet
                            |
                            | HTTP :8080
                            v
                    Public EC2 Instance
                            |
                            | kubectl port-forward
                            v
                    nginx-service
                     NodePort :30080
                            |
                 +----------+----------+
                 |                     |
                 v                     v
            Nginx Pod 1           Nginx Pod 2
                 |                     |
                 +----------+----------+
                            |
                            v
                    EKS Worker Nodes
                    Private Subnets
```

---

## Repository Structure

```text
eks-nginx-demo/
│
├── README.md
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── eks.tf
│   └── .terraform.lock.hcl
│
└── kubernetes/
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

### Terraform

* `main.tf` - VPC and networking configuration
* `variables.tf` - Input variables
* `outputs.tf` - Terraform outputs
* `provider.tf` - Terraform provider configuration
* `eks.tf` - EKS cluster and managed node group

### Kubernetes

* `namespace.yaml` - Kubernetes namespace
* `deployment.yaml` - Nginx Deployment
* `service.yaml` - Nginx Service

---

# Prerequisites

The following tools are required:

* Terraform >= 1.5.0
* AWS CLI v2
* kubectl
* Git
* AWS account with the required permissions

Verify the tools:

```bash
terraform version
aws --version
kubectl version --client
git --version
```

AWS authentication can be provided using an IAM role, environment variables, AWS CLI configuration, or another supported AWS authentication method.

Verify the AWS identity:

```bash
aws sts get-caller-identity
```

No AWS credentials are hardcoded in this repository.

---

# Infrastructure Configuration

## AWS Region

```text
ap-south-1
```

## Availability Zones

```text
ap-south-1a
ap-south-1b
```

## VPC

```text
CIDR: 10.0.0.0/16
```

## Public Subnets

```text
10.0.101.0/24
10.0.102.0/24
```

Public subnets are intended for public-facing resources such as an AWS Load Balancer.

## Private Subnets

```text
10.0.1.0/24
10.0.2.0/24
```

EKS worker nodes are deployed in the private subnets.

## NAT Gateway

A NAT Gateway is configured to provide outbound Internet connectivity for resources in the private subnets.

---

# EKS Configuration

The EKS cluster is provisioned using Terraform.

```text
Cluster Name: nginx-demo-eks
Region: ap-south-1
Kubernetes Version: 1.36
```

The EKS control plane is managed by AWS.

## Worker Node Configuration

The project uses an **AWS-managed EKS managed node group**.

```text
Instance Type: t3.small
Capacity Type: ON_DEMAND

Desired Nodes: 2
Minimum Nodes: 1
Maximum Nodes: 3
```

The worker nodes are deployed in the private subnets.

The `t3.small` instance type is used because the initial `t3.medium` configuration was not eligible for the Free Tier in the AWS account used for this demo.

---

# Deployment Steps

## 1. Clone the Repository

```bash
git clone https://github.com/aditya8112soni-cr/eks-nginx-demo.git
cd eks-nginx-demo
```

---

## 2. Provision EKS Using Terraform

Navigate to the Terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Create a plan:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

Confirm with:

```text
yes
```

Terraform creates the AWS networking infrastructure, EKS cluster, IAM resources, security groups, KMS resources, and EKS managed node group.

---

# 3. Configure kubectl

After the EKS cluster has been created:

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name nginx-demo-eks
```

Verify the cluster:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                                      STATUS   ROLES    VERSION
ip-10-0-1-xxx.ap-south-1.compute.internal Ready    <none>   v1.36.x
ip-10-0-2-xxx.ap-south-1.compute.internal Ready    <none>   v1.36.x
```

The worker nodes should show:

```text
STATUS: Ready
```

---

# 4. Deploy Nginx

Navigate to the Kubernetes directory:

```bash
cd ../kubernetes
```

Create the namespace:

```bash
kubectl apply -f namespace.yaml
```

Deploy Nginx:

```bash
kubectl apply -f deployment.yaml
```

Create the Service:

```bash
kubectl apply -f service.yaml
```

---

# 5. Validate the Nginx Deployment

Check the Deployment:

```bash
kubectl get deployment -n nginx-demo
```

Expected:

```text
NAME              READY   UP-TO-DATE   AVAILABLE
nginx-deployment  2/2     2            2
```

Check the Pods:

```bash
kubectl get pods -n nginx-demo
```

Expected:

```text
NAME                                READY   STATUS    RESTARTS
nginx-deployment-xxxxxxxxxx-aaaaa   1/1     Running   0
nginx-deployment-xxxxxxxxxx-bbbbb   1/1     Running   0
```

The Deployment is configured with:

```yaml
replicas: 2
```

Therefore, Kubernetes maintains two Nginx replicas.

Check which worker nodes are running the Pods:

```bash
kubectl get pods -n nginx-demo -o wide
```

---

# 6. Validate the Kubernetes Service

Check the Service:

```bash
kubectl get svc -n nginx-demo
```

The current working Service configuration is:

```text
Type: NodePort
Service Port: 80
Target Port: 80
Node Port: 30080
```

Expected output:

```text
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx-service   NodePort   172.20.xx.xx    <none>        80:30080/TCP
```

Check the Service endpoints:

```bash
kubectl get endpoints nginx-service -n nginx-demo
```

The endpoints should point to the running Nginx Pods.

---

# 7. Access Nginx Inside the Container

Get the Pod name:

```bash
kubectl get pods -n nginx-demo
```

Open a shell inside the Nginx container:

```bash
kubectl exec -it <pod-name> -n nginx-demo -- /bin/sh
```

Check the Nginx web files:

```bash
ls /usr/share/nginx/html
```

The default Nginx page is:

```text
/usr/share/nginx/html/index.html
```

View the page:

```bash
cat /usr/share/nginx/html/index.html
```

Check Nginx configuration:

```bash
cat /etc/nginx/nginx.conf
```

Check the Nginx version:

```bash
nginx -v
```

Exit the container:

```bash
exit
```

---

# 8. Nginx Logs

View the logs of an Nginx Pod:

```bash
kubectl logs <pod-name> -n nginx-demo
```

Follow the logs:

```bash
kubectl logs -f <pod-name> -n nginx-demo
```

Nginx log files are available inside the container under:

```text
/var/log/nginx/
```

Check them using:

```bash
kubectl exec -it <pod-name> -n nginx-demo -- /bin/sh
```

Then:

```bash
ls /var/log/nginx/
```

Typical files include:

```text
access.log
error.log
```

---

# 9. Test Kubernetes Self-Healing

Delete one of the Nginx Pods:

```bash
kubectl delete pod <pod-name> -n nginx-demo
```

Check the Pods:

```bash
kubectl get pods -n nginx-demo
```

The Deployment automatically creates a replacement Pod to maintain the desired replica count of 2.

Expected final state:

```text
2 Pods
2/2 Running
```

---

# 10. External Access Through AWS Load Balancer

The intended Service configuration is:

```yaml
spec:
  type: LoadBalancer
```

With this configuration, Kubernetes requests an AWS Load Balancer for the Service.

The public subnets are configured with the required load-balancer subnet tags.

However, during testing, the Service remained:

```text
EXTERNAL-IP: <pending>
```

The AWS API returned:

```text
OperationNotPermitted:
This AWS account currently does not support creating load balancers.
```

A direct AWS ELB API test produced the same restriction.

Therefore, an AWS Load Balancer could not be created in the account during testing.

---

# 11. Working External Access Using EC2

For the working demonstration, the Service was configured as:

```yaml
spec:
  type: NodePort
```

with:

```yaml
nodePort: 30080
```

The EKS worker nodes are in private subnets, so they are not directly accessible from the Internet.

A public EC2 administration machine is therefore used to provide temporary external access.

Run:

```bash
kubectl port-forward \
  -n nginx-demo \
  svc/nginx-service \
  8080:80 \
  --address 0.0.0.0
```

The traffic flow is:

```text
Browser
   |
   | HTTP :8080
   v
EC2 Public IP
   |
   | kubectl port-forward
   v
nginx-service :80
   |
   v
Nginx Pods :80
```

The EC2 Security Group allows inbound TCP traffic on port `8080` from the administrator's public IP.

The application can then be accessed using:

```text
http://<EC2-PUBLIC-IP>:8080
```

Example:

```text
http://13.204.79.45:8080
```

The expected result is the Nginx default page:

```text
Welcome to nginx!
```

> **Note:** `kubectl port-forward` is a temporary testing mechanism. The command must remain running for external access to continue.

---

# 12. Application Traffic Flow

### Current Working Demo

```text
Internet
   |
   | :8080
   v
EC2 Public IP
   |
   | port-forward
   v
Kubernetes Service
   |
   | selector: app=nginx
   |
   +-------------------+
   |                   |
   v                   v
Nginx Pod 1        Nginx Pod 2
   |                   |
   +---------+---------+
             |
             v
       EKS Worker Nodes
       Private Subnets
```

### Intended Assignment Architecture

```text
Internet
   |
   v
AWS Network Load Balancer
   |
   v
Kubernetes LoadBalancer Service
   |
   +-------------------+
   |                   |
   v                   v
Nginx Pod 1        Nginx Pod 2
   |                   |
   +---------+---------+
             |
             v
       EKS Worker Nodes
       Private Subnets
```

---

# 13. Resource Functions

## VPC

Provides the isolated AWS network for the EKS environment.

```text
10.0.0.0/16
```

## Public Subnets

Used for public-facing resources such as the intended AWS Load Balancer.

```text
10.0.101.0/24
10.0.102.0/24
```

## Private Subnets

Used for EKS worker nodes.

```text
10.0.1.0/24
10.0.2.0/24
```

## Internet Gateway

Provides Internet connectivity for resources in public subnets.

## NAT Gateway

Provides outbound Internet connectivity for resources in private subnets.

## Route Tables

Control where network traffic is routed within the VPC.

## Security Groups

Act as virtual firewalls controlling network traffic to AWS resources.

## EKS

Provides the managed Kubernetes control plane.

## EKS Managed Node Group

Provides the EC2 worker nodes where Kubernetes Pods run.

## Kubernetes Deployment

Maintains the desired number of Nginx Pods.

## Kubernetes Service

Provides stable networking and routes traffic to the Nginx Pods.

## Nginx Container

Runs the Nginx web server and serves the default Nginx page.

---

# 14. Terraform Validation

Navigate to the Terraform directory:

```bash
cd terraform
```

Format:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Review the current infrastructure:

```bash
terraform plan
```

Expected result when there are no configuration changes:

```text
No changes.
Your infrastructure matches the configuration.
```

This confirms that the deployed AWS infrastructure matches the Terraform configuration.

---

# 15. Terraform Outputs

View the Terraform outputs:

```bash
terraform output
```

The project provides outputs including:

* EKS cluster name
* EKS cluster endpoint
* EKS cluster version
* VPC ID
* Private subnet IDs
* Public subnet IDs
* AWS region
* kubectl configuration command

---

# 16. Troubleshooting

## Pods are Pending

Check:

```bash
kubectl get pods -n nginx-demo
```

Describe the Pod:

```bash
kubectl describe pod <pod-name> -n nginx-demo
```

Check nodes:

```bash
kubectl get nodes
```

Check events:

```bash
kubectl get events -n nginx-demo
```

---

## Pod is CrashLoopBackOff

Check logs:

```bash
kubectl logs <pod-name> -n nginx-demo
```

Check previous logs:

```bash
kubectl logs <pod-name> -n nginx-demo --previous
```

Describe the Pod:

```bash
kubectl describe pod <pod-name> -n nginx-demo
```

---

## Service Has No Endpoints

Check:

```bash
kubectl get endpoints nginx-service -n nginx-demo
```

Check Pod labels:

```bash
kubectl get pods -n nginx-demo --show-labels
```

The Service selector should match the Pod label:

```text
app=nginx
```

---

## LoadBalancer EXTERNAL-IP Is Pending

Check:

```bash
kubectl get svc nginx-service -n nginx-demo
```

Describe the Service:

```bash
kubectl describe svc nginx-service -n nginx-demo
```

If AWS returns:

```text
OperationNotPermitted:
This AWS account currently does not support creating load balancers.
```

the account is currently restricted from creating Elastic Load Balancers.

For this demo, use the NodePort and EC2 port-forward method described above.

---

## kubectl Unauthorized

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name nginx-demo-eks
```

Verify the AWS identity:

```bash
aws sts get-caller-identity
```

Then:

```bash
kubectl get nodes
```

---

## Terraform Apply Fails

Check the AWS identity:

```bash
aws sts get-caller-identity
```

Validate Terraform:

```bash
terraform validate
```

Review the plan:

```bash
terraform plan
```

---

# 17. Useful Kubernetes Commands

### Check all resources

```bash
kubectl get all -n nginx-demo
```

### Check nodes

```bash
kubectl get nodes
```

### Check Pods

```bash
kubectl get pods -n nginx-demo
```

### Check Pods with node information

```bash
kubectl get pods -n nginx-demo -o wide
```

### Check Deployment

```bash
kubectl get deployment -n nginx-demo
```

### Check Service

```bash
kubectl get svc -n nginx-demo
```

### Check endpoints

```bash
kubectl get endpoints nginx-service -n nginx-demo
```

### Describe Pod

```bash
kubectl describe pod <pod-name> -n nginx-demo
```

### View logs

```bash
kubectl logs <pod-name> -n nginx-demo
```

### Follow logs

```bash
kubectl logs -f <pod-name> -n nginx-demo
```

### Enter the container

```bash
kubectl exec -it <pod-name> -n nginx-demo -- /bin/sh
```

---

# 18. Cleanup / Destroy

Remove the Kubernetes resources first:

```bash
cd kubernetes

kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f namespace.yaml
```

Then destroy the AWS infrastructure:

```bash
cd ../terraform

terraform destroy
```

Confirm with:

```text
yes
```

---

# 19. Security Notes

* No AWS credentials are hardcoded in the repository.
* AWS IAM roles should be preferred over long-lived access keys.
* Terraform state files should not be committed to GitHub.
* `.terraform/` should not be committed.
* Sensitive `.tfvars` files should not be committed.
* EC2 SSH access should be restricted to trusted IP addresses.
* Temporary port `8080` access should be restricted to the administrator's public IP.
* EKS public API endpoint access should be restricted for production environments.
* Production environments should use a secure remote Terraform state backend.
* The current EC2 port-forward method is for demonstration/testing and is not intended as a production exposure mechanism.

---

# 20. Expected Final Result

After successful deployment:

```text
EKS Cluster
    |
    +--- Worker Node 1       Ready
    |
    +--- Worker Node 2       Ready
             |
             |
       Nginx Deployment
             |
       +-----+-----+
       |           |
       v           v
    Nginx Pod 1  Nginx Pod 2
       |           |
       +-----+-----+
             |
       nginx-service
             |
        NodePort :30080
             |
      EC2 port-forward
             |
       Public EC2 IP
             |
          Browser
             |
      Welcome to nginx!
```

The following requirements are demonstrated:

* EKS cluster created using Terraform
* AWS VPC and networking created using Terraform
* EKS worker nodes created using an AWS-managed node group
* Two Nginx replicas running
* Kubernetes Service configured
* Pods scheduled and running
* Nginx default page accessible externally through the working EC2-based demonstration
* Kubernetes self-healing verified
* Terraform configuration validated
* Infrastructure managed through GitHub

---

# Technologies Used

* AWS
* Amazon EKS
* Amazon EC2
* Amazon VPC
* AWS IAM
* AWS NAT Gateway
* AWS Internet Gateway
* Terraform
* Kubernetes
* Nginx
* kubectl
* Git
* GitHub

---

# GitHub Repository

[https://github.com/aditya8112soni-cr/eks-nginx-demo](https://github.com/aditya8112soni-cr/eks-nginx-demo)
