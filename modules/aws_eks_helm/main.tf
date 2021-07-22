terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.50.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
  }
}

module "eks" {
  source          = "./eks"
  deployment_name = var.deployment_name
}

module "helm" {
  source                    = "./helm"
  deployment_name           = var.deployment_name
  eks_endpoint              = module.eks.eks_endpoint
  eks_name                  = module.eks.eks_name
  eks_certificate_authority = module.eks.eks_certificate_authority

  values_path = "${path.module}/retool-values.yml"
}
