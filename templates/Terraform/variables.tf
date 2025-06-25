# variables.tf - Variable definitions for Azure SQL Infrastructure

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  #default     = "sql-infrastructure-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_E2s_v3"
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "SQLVnet"
}

variable "virtual_network_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "default_subnet_address_prefix" {
  description = "Address prefix for the default subnet"
  type        = list(string)
  default     = ["10.2.0.0/24"]
}

variable "bastion_subnet_address_prefix" {
  description = "Address prefix for the bastion subnet"
  type        = list(string)
  default     = ["10.2.1.0/24"]
}

variable "dns_servers" {
  description = "DNS servers for the virtual network"
  type        = list(string)
  default     = ["10.2.0.4"]
}

variable "dc_vm_name" {
  description = "Name of the Domain Controller VM"
  type        = string
  default     = "SQLDCVM"
}

variable "sql_vm_names" {
  description = "Names of the SQL Server VMs"
  type        = map(string)
  default = {
    sql1 = "SQL1VM"
    sql2 = "SQL2VM"
    sql3 = "SQL3VM"
  }
}

variable "availability_set_name" {
  description = "Name of the availability set"
  type        = string
  default     = "SQLAS"
}

variable "bastion_name" {
  description = "Name of the Azure Bastion host"
  type        = string
  default     = "SQLbastion"
}

variable "bastion_public_ip_name" {
  description = "Name of the Bastion public IP"
  type        = string
  default     = "BastEndpoint"
}

variable "vm_private_ips" {
  description = "Static private IP addresses for VMs"
  type        = map(string)
  default = {
    dc   = "10.2.0.4"
    sql1 = "10.2.0.5"
    sql2 = "10.2.0.6"
    sql3 = "10.2.0.7"
  }
}

variable "sql_connectivity_port" {
  description = "SQL Server connectivity port"
  type        = number
  default     = 1433
}

variable "sql_license_type" {
  description = "SQL Server license type"
  type        = string
  default     = "PAYG"
  validation {
    condition     = contains(["PAYG", "AHUB"], var.sql_license_type)
    error_message = "SQL license type must be either PAYG or AHUB."
  }
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 1024
}

variable "storage_account_type" {
  description = "Storage account type for managed disks"
  type        = string
  default     = "Premium_LRS"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "SQL Infrastructure"
    Project     = "SQL Server Deployment"
    ManagedBy   = "Terraform"
  }
}