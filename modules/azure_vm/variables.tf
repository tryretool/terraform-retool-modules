variable "commandtoexecute" {
  type        = string
  description = "Commands to run at vm startup"
  default     = ""
}

variable "db_instance_size" {
  type        = string
  description = "Instance size for external Azure Postgres server"
  default     = "GP_Standard_D4s_v3"
}

variable "external_psql" {
  type        = bool
  description = "Option to create an Azure Postgres server for retool backend"
  default     = false
}

variable "security_rules" {
  type = list(
    object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })
  )
  default = [
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
  description = "Ingress rules for EC2 security group"
}

variable "instance_size" {
  type        = string
  description = "Retool instance size"
  default     = "Standard_D4_v4"
}

variable "psql_password" {
  type        = string
  description = "Admin password sername for postgres database"
  default     = "mysupersecurepassword123"
}

variable "psql_subnet_cidr" {
  type        = list(string)
  description = "CIDR block for database subnet"
  default     = ["10.0.2.0/24"]
}

variable "psql_user" {
  type        = string
  description = "Admin username for postgres database"
  default     = "retool"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group to create resources in"
}

variable "ssh_key_path" {
  type        = string
  description = "Path to SSH key for connection to VM"
  default     = "~/.ssh/id_rsa.pub"
}

variable "subnet_name" {
  type        = string
  description = "Existing subnet to create resources in"
}

variable "version_number" {
  type        = string
  description = "Retool version"
}

variable "virtual_network_name" {
  type        = string
  description = "Existing vnet to create resources in"
}