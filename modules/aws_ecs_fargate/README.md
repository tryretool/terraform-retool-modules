# AWS ECS + Fargate Module

This module deploys and ECS cluster with AWS Fargate. This eliminates the need to manually provision, scale and manage compute instances.

# Key Design Decisions

The module will deploy an RDS instance in the same VPC as the Fargate cluster.

# Usage

1. Directly use our module in your existing Terraform configuration and provide the required variables

```
module "retool" {
    ...
}
```
