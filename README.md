This repository contains official Terraform modules for installing and configuring Retool. For full documentation on all the ways you can deploy Retool on your own infrastructure, please see the [Setup Guide](https://docs.retool.com/docs/setup-instructions).


# Prerequisites
- All modules utilize **Hashicorp Terraform 3.50.0**
- We currently only support an ECS + EC2 deployment on AWS at this time

# Usage
1. Directly use our module in your existing Terraform configuration and provide the required variables

```
module "retool" {
    source = "git@github.com:tryretool/retool-terraform.git//modules/aws/ecs-ec2"

    aws_region = "<your-aws-region>"
    vpc_id = "<your-vpc-id>"
    subnet_ids = [
        "<your-subnet-1>",
        "<your-subnet-2>"
    ]
    ssh_key_pair = "<your-key-pair>"
    ecs_retool_image = "<desired-retool-version>"

    # Additional configuration
    ...
}
```

2. Run `terraform init` to install all requirements for the module.

3. Replace `ecs_retool_image` with your desired [Retool Version](https://docs.retool.com/docs/updating-retool-on-premise#retool-release-versions). The format should be `tryretool/backend:X.Y.Z`, where `X.Y.Z` is your desired version number.

4. Ensure that the default security settings in `security.tf` matches your specifications. If you need to tighten down access, copy the source code and modify the security groups as needed.

5. Check through `variables.tf` for any other input variables that may be required.

6. Run `terraform plan` to view all planned changes to your account.

7. Run `terraform apply` to apply the changes and deploy Retool.
