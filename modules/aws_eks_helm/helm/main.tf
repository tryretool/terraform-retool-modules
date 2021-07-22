provider "helm" {
  kubernetes {
    host                   = var.eks_endpoint
    cluster_ca_certificate = base64decode(var.eks_certificate_authority)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "retool" {
  name       = "${var.deployment_name}-helm-release"
  repository = "https://github.com/tryretool/retool-helm"
  chart      = "retool/retool"

  values = [file(var.values_path)]
}