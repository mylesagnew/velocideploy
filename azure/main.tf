terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.64.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "tls_private_key" "tls-velo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.case_name}-rg"
  location = "East US" # Change to your preferred Azure region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.case_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.case_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.case_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsg_rule_ssh" {
  name                        = "Allow-SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${chomp(data.http.my_ip.response_body)}/32"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsg_rule_velo_frontend" {
  name                        = "Allow-Frontend"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsg_rule_velo_gui" {
  name                        = "Allow-GUI"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8889"
  source_address_prefix       = "${chomp(data.http.my_ip.response_body)}/32"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.case_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.case_name}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.case_name}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  size = "Standard_B2ms" # Adjust to desired instance type

  os_disk {
    name              = "${var.case_name}-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = 1024
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  admin_username = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.tls-velo.public_key_openssh
  }

  tags = {
    Name = "${var.case_name}"
  }
}

resource "local_file" "private_key" {
  content        = tls_private_key.tls-velo.private_key_pem
  filename       = "${var.case_name}.pem"
  file_permission = "0400"
}

resource "local_file" "ansible-inventory" {
  filename = "./inventory"
  content     = <<EOF
[ubuntu]
${azurerm_public_ip.public_ip.ip_address}

[ubuntu:vars]
ansible_user=azureuser
ansible_ssh_private_key_file=./${var.case_name}.pem
EOF
}

resource "null_resource" "ssh_command" {
  provisioner "local-exec" {
    command = "echo $'\nssh -i ${var.case_name}.pem azureuser@${azurerm_public_ip.public_ip.ip_address}' >> velociraptor.sh"
  }
}
