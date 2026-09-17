variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "nginx-demo-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (worker nodes)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (load balancers / NAT)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment tag applied to resources"
  type        = string
  default     = "demo"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "eks-nginx-demo"
    ManagedBy = "terraform"
  }
}
