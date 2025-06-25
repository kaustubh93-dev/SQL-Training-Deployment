# terraform.tfvars - Variable values for Azure SQL Infrastructure deployment

# Basic Configuration
resource_group_name = "sql-infrastructure-rg"
location            = "Central US"

# VM Configuration
admin_username = "adminuser"
admin_password = "Password123!" # Change this to a secure password
vm_size        = "Standard_E2s_v3"

# Network Configuration
virtual_network_name          = "SQLVnet"
virtual_network_address_space = ["10.2.0.0/16"]
default_subnet_address_prefix = ["10.2.0.0/24"]
bastion_subnet_address_prefix = ["10.2.1.0/24"]
dns_servers                   = ["10.2.0.4"]

# VM Names
dc_vm_name = "SQLDCVM"
sql_vm_names = {
  sql1 = "SQL1VM"
  sql2 = "SQL2VM"
  sql3 = "SQL3VM"
}

# Static IP Addresses
vm_private_ips = {
  dc   = "10.2.0.4"
  sql1 = "10.2.0.5"
  sql2 = "10.2.0.6"
  sql3 = "10.2.0.7"
}

# Infrastructure Names
availability_set_name  = "SQLAS"
bastion_name           = "SQLbastion"
bastion_public_ip_name = "BastEndpoint"

# SQL Server Configuration
sql_connectivity_port = 1433
sql_license_type      = "PAYG" # Options: "PAYG" or "AHUB"

# Storage Configuration
os_disk_size_gb      = 1024
storage_account_type = "Premium_LRS"

# Tags
tags = {
  Environment = "Development"
  Project     = "SQL Server Infrastructure"
  Owner       = "Database Team"
  ManagedBy   = "Terraform"
  CostCenter  = "IT"
}