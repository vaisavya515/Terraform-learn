terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.azure-subscription-id
  tenant_id       = var.azure-tenant-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
}

data "azurerm_resource_group" "terraform" {
  name = "Terraform-RG"
}

resource "azurerm_virtual_network" "terraform" {
  name                = "TF-VM-Network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name
}

resource "azurerm_subnet" "terraform" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.terraform.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "terraform" {
  name                = "myPublicIP"
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic"
}
resource "azurerm_network_security_group" "terraform" {
  name                = "TF-VM-2-NSG"
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name

  security_rule {
    name                       = "PORT_3000"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "terraform" {
  name                = "TF-nic"
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraform.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.terraform.id}"
  }
}
resource "azurerm_network_interface_security_group_association" "vmscripts" {
  network_interface_id      = azurerm_network_interface.terraform.id
  network_security_group_id = azurerm_network_security_group.terraform.id
}
resource "azurerm_windows_virtual_machine" "terraform" {
  name                = "TF-VM-2"
  resource_group_name = data.azurerm_resource_group.terraform.name
  location            = data.azurerm_resource_group.terraform.location
  size                = "Standard_F2"
  admin_username      = "vaishu"
  admin_password      = "Mindtree.@123"
  network_interface_ids = [
    azurerm_network_interface.terraform.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  
}
