# AWS ECS + EC2 Module

This module deploys an ECS cluster with autoscaling group of EC2 instances.

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

8. You should now find a Load Balancer in your AWS EC2 Console associated with the deployment. The instance address should now be running Retool.

## Common Configuration

### Instances

**EC2 Instance Size**
To configure the EC instance size, set the `instance_type` input variable (e.g. `t2.large`).

**RDS Instance Class**
To configure the RDS instance class, set the `instance_class` input variable (e.g. `db.m4.large`).

## Advanced Configuration

### Environment Variables
To add additional [Retool environment variables](https://docs.retool.com/docs/environment-variables) to your deployment, populate the `additional_env_vars` input variable into the module.

NOTE: The `additional_env_vars` will only work as type `map(string)`. Convert all booleans and numbers into strings, e.g.

```
additional_env_vars = [
    {
        name = "DISABLE_GIT_SYNCING"
        value = "true"
    }
]
```
