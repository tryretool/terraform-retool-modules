provider "aws" {
  region = var.aws_region
}

resource "aws_eks_cluster" "this" {
  name     = "${var.deployment_name}-eks"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller
  ]
}
