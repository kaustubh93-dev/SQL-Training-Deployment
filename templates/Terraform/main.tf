# main.tf - Main Terraform configuration for Azure SQL Infrastructure

# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Availability Set
resource "azurerm_availability_set" "sql_as" {
  name                = var.availability_set_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  managed             = true

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = var.tags
}

# Create Public IP for Bastion
resource "azurerm_public_ip" "bastion_ip" {
  name                = var.bastion_public_ip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Virtual Network
resource "azurerm_virtual_network" "sql_vnet" {
  name                = var.virtual_network_name
  address_space       = var.virtual_network_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_servers         = var.dns_servers
  tags                = var.tags
}

# Create Default Subnet
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.sql_vnet.name
  address_prefixes     = var.default_subnet_address_prefix
}

# Create Azure Bastion Subnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.sql_vnet.name
  address_prefixes     = var.bastion_subnet_address_prefix
}

# Create Network Security Group for SQL VMs
resource "azurerm_network_security_group" "sql_nsg" {
  name                = "sql-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.sql_connectivity_port)
    source_address_prefix      = "10.2.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.2.0.0/16"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Interface for Domain Controller VM
resource "azurerm_network_interface" "dc_nic" {
  name                = "SQLdcvmNIC"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ips.dc
  }

  tags = var.tags
}

# Network Interfaces for SQL VMs
resource "azurerm_network_interface" "sql_nics" {
  for_each            = var.sql_vm_names
  name                = "${each.value}NIC"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ips[each.key]
  }

  tags = var.tags
}

# Associate Network Security Group to SQL NICs
resource "azurerm_network_interface_security_group_association" "sql_nsg_associations" {
  for_each                  = var.sql_vm_names
  network_interface_id      = azurerm_network_interface.sql_nics[each.key].id
  network_security_group_id = azurerm_network_security_group.sql_nsg.id
}

# Domain Controller Virtual Machine
resource "azurerm_windows_virtual_machine" "dc_vm" {
  name                = var.dc_vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  #disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.dc_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  tags = merge(var.tags, {
    Role = "Domain Controller"
  })
}

# SQL Server Virtual Machines
resource "azurerm_windows_virtual_machine" "sql_vms" {
  for_each            = var.sql_vm_names
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  availability_set_id = azurerm_availability_set.sql_as.id

  #disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.sql_nics[each.key].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "microsoftsqlserver"
    offer     = "sql2019-ws2019"
    sku       = "sqldev"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  tags = merge(var.tags, {
    Role = "SQL Server"
  })
}

# SQL Virtual Machine Extensions
resource "azurerm_mssql_virtual_machine" "sql_vm_configs" {
  for_each                         = var.sql_vm_names
  virtual_machine_id               = azurerm_windows_virtual_machine.sql_vms[each.key].id
  sql_license_type                 = var.sql_license_type
  r_services_enabled               = false
  sql_connectivity_port            = var.sql_connectivity_port
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = var.admin_password
  sql_connectivity_update_username = var.admin_username

  tags = var.tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "sql_bastion" {
  name                = var.bastion_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }

  tags = var.tags
}

# Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.sql_vnet.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = azurerm_public_ip.bastion_ip.ip_address
}

output "domain_controller_private_ip" {
  description = "Private IP address of the Domain Controller"
  value       = azurerm_network_interface.dc_nic.private_ip_address
}

output "sql_vm_private_ips" {
  description = "Private IP addresses of SQL VMs"
  value = {
    for k, v in azurerm_network_interface.sql_nics : k => v.private_ip_address
  }
}

output "sql_vm_names" {
  description = "Names of the created SQL VMs"
  value = {
    for k, v in azurerm_windows_virtual_machine.sql_vms : k => v.name
  }
}