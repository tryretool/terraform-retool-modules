# AWS EC2 Standalone Deployment

## Requirements

- RDS instance with port, host, username, and password
- VPC with desired subnets

## Usage

1. Directly use our module in your existing Terraform configuration and provide the required variables

```
module "retool" {
    source = "git@github.com:tryretool/terraform-retool-modules.git//modules/aws_ec2_standalone"

    aws_region = "<your-aws-region>"
    vpc_id = "<your-vpc-id>"
    subnet_id = "<your-subnet-1>"
    ssh_key_name = "<your-key-pair-name>"
    version_number = "<desired-retool-version (e.g. 2.69.18)>"

    # Additional configuration
    ...
    ingress_rules = [
        ...
    ]
    egress_rules = [
        ...
    ]
}
```

2. Run `terraform plan` to confirm that the changes look good

3. Run `terraform apply` to apply the configuration changes

4. After a few minutes, SSH into your newly created EC2 instance using the Key Pair passed into `ssh_key_name`

5. Verify that the GitHub repository exists

```
sudo su - root
cd /retool-onpremise
```

6. Verify that the Dockerfile contains the correct Retool version number

```
# you should see the X.Y.Z version number specified
vim Dockerfile
```

7. Verify that all of the Docker containers are up and running. If one of them is not running or restarting, try re-creating the containers with (`docker-compose up -d`)

```
docker-ps
```

8. Modify your environment variables. If you have an external RDS database (strongly recommended), replace the `POSTGRES_` environment variables with the new ones.

- If testing out your instance for the first time without SSL/HTTPS, you should uncomment `# COOKIE_INSECURE = true`
- Replace your `LICENSE_KEY` with your provided Retool license key

9. Add any additional configuration needed. You can refer to our documentation for [all additional environment variables](https://docs.retool.com/docs/environment-variables).

10. Access your Retool instance on the ec2_public_dns that is given via the resource creation outputs. If no SSL certificate has been configured you need to access the instance on port 3000 (append :3000 to the end of the URL) and via http.

### Security Group

You can configure the security group ingress and egress rules using input variables:

```
ingress_rules = [
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
    },
    {
      description      = "Application port inbound"
      from_port        = "3000"
      to_port          = "3000"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
]
egress_rules = [
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

By default, this module creates a publicly-accessible security group that enables inbound traffic on ports (`30`, `443`, `22`, and `3000`) and all outbound traffic.
