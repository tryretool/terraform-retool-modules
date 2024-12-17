# AWS ECS + EC2 Module

This module deploys an ECS cluster with autoscaling group of EC2 instances.

# Usage

1. Directly use our module in your existing Terraform configuration and provide the required variables

```
module "retool" {
    source = "git@github.com:tryretool/terraform-retool-modules.git//modules/aws_ecs"

    aws_region = "<your-aws-region>"
    vpc_id = "<your-vpc-id>"
    subnet_ids = [
        "<your-subnet-1>",
        "<your-subnet-2>"
    ]
    ssh_key_name = "<your-key-pair>"
    ecs_retool_image = "<desired-retool-version>"
    workflows_enabled = true

    # Additional configuration
    ...
}
```

2. Run `terraform init` to install all requirements for the module.

3. Replace `ecs_retool_image` with your desired [Retool Version](https://docs.retool.com/docs/updating-retool-on-premise#retool-release-versions). The format should be `tryretool/backend:X.Y.Z`, where `X.Y.Z` is your desired version number. Version 2.111 or greater is needed for Workflows (2.117 or later strongly recommended for performance improvements).

4. Ensure that the default security settings in `security.tf` matches your specifications. If you need to tighten down access, pass in custom ingress and egress rules into `container_egress_rules`, `container_ingress_rules`, `alb_egress_rules`, and `alb_ingress_rules`.

5. Check through `variables.tf` for any other input variables that may be required. Set `launch_type` to `EC2` if not using Fargate.

6. Run `terraform plan` to view all planned changes to your account.

7. Run `terraform apply` to apply the changes and deploy Retool.

8. You should now find a Load Balancer in your AWS EC2 Console associated with the deployment. The instance address should now be running Retool.

## Common Configuration

### Instances

**EC2 Instance Size**
To configure the EC instance size, set the `instance_type` input variable (e.g. `t2.large`).

**RDS Instance Class**
To configure the RDS instance class, set the `instance_class` input variable (e.g. `db.m6g.large`).

## Advanced Configuration
**Bring your own Temporal Cluster**
To configure your own Temporal cluster, set the `use_existing_temporal_cluster` to `true` and configure your Temporal Cluster's Frontend service endpoint (and TLS if needed) using `temporal_cluster_config`. If configuring mTLS, we expect the cert and key values to be base64-encoded strings.
### Security Groups

To customize the ingress and egress rules on the security groups, you can override specific input variable defaults.

- `container_ingress_rules` controls the inbound rules for EC2 instances in autoscaling group or ECS services in Fargate
- `container_egress_rules` controls the outbound rules for EC2 instances in autoscaling group or ECS services in Fargate
- `alb_ingress_rules` controls the inbound rules for the Load Balancer
- `alb_egress_rules` controls the outbound rules for the Load Balancer

```
container_ingress_rules = [
    {
      description      = "Global HTTP inbound"
      from_port        = "80"
      to_port          = "80"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "Global HTTPS inbound"
      from_port        = "443"
      to_port          = "443"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "SSH inbound"
      from_port        = "22"
      to_port          = "22"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
]

container_egress_rules = [
    {
      description      = "Global outbound"
      from_port        = "0"
      to_port          = "0"
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
]
```

### Telemetry
**Note: telemetry collection is currently supported only on Fargate clusters.**

To enable telemetry collection, set the variable `telemetry_enabled` to `true` (see [variables.tf](variables.tf#L340)).
You may also enable forwarding telemetry data to Retool by setting the variable `telemetry_send_to_retool` to `true`.

Similar to Helm deployments, [custom configuration](https://docs.retool.com/self-hosted/guides/telemetry#send-telemetry-data-to-custom-destinations) may be passed into the Retool telemetry collector.
To use custom configuration, set [`telemetry_use_custom_config`](variables.tf#L352) to `true`, and supply your custom config in the file named in [`telemetry_custom_config_path`](variables.tf#L358).

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

### SSL Certificate and HTTP redirect to HTTPS
The following example terraform snippets show how to set up an http to https redirect, as well as an https listener on the ALB.
Add this to the module declaration:
```
  alb_http_redirect = true
  alb_ingress_rules = [
    {
      description      = "Global HTTP inbound"
      from_port        = "80"
      to_port          = "80"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "Global HTTP inbound"
      from_port        = "443"
      to_port          = "443"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]

```

The following creates a certificate and an https listener using that cert:
```
resource "aws_acm_certificate" "cert" {
  domain_name       = "retool.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = module.retool.ecs_alb_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = module.retool.target_group_arn
  }
}

output "domain_validation" {
  value = aws_acm_certificate.cert.domain_validation_options
}
```

