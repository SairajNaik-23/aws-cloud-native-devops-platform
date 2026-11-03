# Managed Kubernetes cluster (EKS) with a managed node group
# running in the private subnets.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow kubectl access from your laptop / Jenkins server
  cluster_endpoint_public_access = true

  # The IAM identity that runs `terraform apply` becomes cluster admin
  enable_cluster_creator_admin_permissions = true

  # Give the Jenkins server's IAM role kubectl access (only if a role ARN is set)
  access_entries = {
    for name, arn in { jenkins = var.jenkins_role_arn } : name => {
      principal_arn            = arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    } if arn != ""
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }
}
