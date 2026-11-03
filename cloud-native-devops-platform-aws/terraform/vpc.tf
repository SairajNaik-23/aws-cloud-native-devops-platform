# Network layer: a VPC spread across 2 Availability Zones.
#  - Public subnets  -> AWS Load Balancers (internet facing)
#  - Private subnets -> EKS worker nodes (not directly reachable from internet)
#  - NAT Gateway     -> lets private nodes pull images / updates from internet

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]      # 10.0.0.0/24, 10.0.1.0/24
  private_subnets = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 10)] # 10.0.10.0/24, 10.0.11.0/24

  enable_nat_gateway   = true
  single_nat_gateway   = true # one NAT keeps cost low for dev; use one per AZ in prod
  enable_dns_hostnames = true

  # Tags required so Kubernetes knows where to create load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
