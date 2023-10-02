# Azure VM Standalone Deployment

## Requirements

- VPC with desired subnets

## Usage

1. Directly use our module in your existing Terraform configuration and provide the required variables

```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

provider "azurerm" {
  features {}
}


module "retool" {
  source               = "git@github.com:tryretool/retool-terraform.git//modules/azure_vm"
  resource_group_name  = "<resource-group-name>"
  subnet_name          = "<subnet-name>"
  version_number       = "<desired-retool-version eg 3.12.4>"
  virtual_network_name = "<vnet-name>"
}

output "vm_public_ip" {
  value = module.retool.vm_public_ip
  description = "Public IP of VM Instance"
}
```
2. Copy `vm_script.sh` to your local Terraform directory.

3. Run `terraform plan` to confirm that the changes look good

4. Run `terraform apply` to apply the configuration changes

5. After a few minutes, SSH into your newly created EC2 instance using the Key Pair passed into `ssh_key_path`, defaults to `~/.ssh/id_rsa.pub`

6. Verify that the GitHub repository exists

```
sudo su - 
cd /retool/retool-onpremise
```

7. Verify that the Dockerfile contains the correct Retool version number

```
# you should see the X.Y.Z version number specified
vim Dockerfile
```

8. Verify that all of the Docker containers are up and running. If one of them is not running or restarting, try re-creating the containers with (`docker-compose up -d`)

```
docker-ps
```

9. Modify your environment variables. If you have an external RDS database (strongly recommended), replace the `POSTGRES_` environment variables with the new ones.

- If testing out your instance for the first time without SSL/HTTPS, you should uncomment `# COOKIE_INSECURE = true`
- Replace your `LICENSE_KEY` with your provided Retool license key

10. Add any additional configuration needed. You can refer to our documentation for [all additional environment variables](https://docs.retool.com/docs/environment-variables).

11. Access your Retool instance on the public IP that is given via the resource creation outputs. If no SSL certificate has been configured you need to access the instance on port 3000 (append :3000 to the end of the URL) and via http.

### Security Rules

You can configure the security group ingress and egress rules using input variables:

For example, to create a Retool instance accessible from anywhere, you can use the following value for `security_rules` which enables inbound traffic on ports (`30`, `443`, `22`, and `3000`) and all outbound traffic. Note that this is also the default behavior of this module.

```
  security_rules = [
    {
      name                       = "GlobalHTTP"
      priority                   = 300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "GlobalHTTPS"
      priority                   = 310
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "SSH"
      priority                   = 320
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "ApplicationPort"
      priority                   = 330
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
```

