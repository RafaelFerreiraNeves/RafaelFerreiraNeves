module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = var.aws_vpc_name
  cidr = var.aws_vpc_cidr

  azs             = var.aws_vpc_azs
  private_subnets = var.aws_vpc_private_subnets
  public_subnets  = var.aws_vpc_public_subnets

  # ⚠️ Evita custo alto desnecessário
  enable_nat_gateway = false

  enable_vpn_gateway = true

  tags = merge(
    var.aws_project_tags,
    {
      "kubernetes.io/cluster/${var.aws_eks_name}" = "shared"
    }
  )

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.aws_eks_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.aws_eks_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0"

  cluster_name    = var.aws_eks_name

  # ✅ Versão válida (evita erro de downgrade)
  cluster_version = "1.29"

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name = "default"

      min_size     = 1
      max_size     = 1
      desired_size = 1

      # ✅ Tipo seguro (evita erro e custo alto)
      instance_types = ["t3.micro"]

      # ✅ Evita erro de AMI
      ami_type = "AL2_x86_64"

      capacity_type = "ON_DEMAND"

      tags = var.aws_project_tags
    }
  }

  tags = var.aws_project_tags
}
