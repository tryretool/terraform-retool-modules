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


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.74 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.74 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_machine_extension.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_resource_group.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_commandtoexecute"></a> [commandtoexecute](#input\_commandtoexecute) | Commands to run at vm startup | `string` | `""` | no |
| <a name="input_instance_size"></a> [instance\_size](#input\_instance\_size) | Retool instance size | `string` | `"Standard_D4_v4"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Existing resource group to create resources in | `string` | n/a | yes |
| <a name="input_security_rules"></a> [security\_rules](#input\_security\_rules) | Ingress rules for EC2 security group | <pre>list(<br>    object({<br>      name                       = string<br>      priority                   = number<br>      direction                  = string<br>      access                     = string<br>      protocol                   = string<br>      source_port_range          = string<br>      destination_port_range     = string<br>      source_address_prefix      = string<br>      destination_address_prefix = string<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port_range": "80",<br>    "direction": "Inbound",<br>    "name": "GlobalHTTP",<br>    "priority": 300,<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port_range": "*"<br>  },<br>  {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port_range": "443",<br>    "direction": "Inbound",<br>    "name": "GlobalHTTPS",<br>    "priority": 310,<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port_range": "*"<br>  },<br>  {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port_range": "22",<br>    "direction": "Inbound",<br>    "name": "SSH",<br>    "priority": 320,<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port_range": "*"<br>  },<br>  {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port_range": "3000",<br>    "direction": "Inbound",<br>    "name": "ApplicationPort",<br>    "priority": 330,<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port_range": "*"<br>  }<br>]</pre> | no |
| <a name="input_ssh_key_path"></a> [ssh\_key\_path](#input\_ssh\_key\_path) | Path to SSH key for connection to VM | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Existing subnet to create resources in | `string` | n/a | yes |
| <a name="input_version_number"></a> [version\_number](#input\_version\_number) | Retool version | `string` | n/a | yes |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | Existing vnet to create resources in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vm_public_ip"></a> [vm\_public\_ip](#output\_vm\_public\_ip) | Public IP of VM Instance |
<!-- END_TF_DOCS -->