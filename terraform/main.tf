terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
    features {}
    subscription_id = "08b7b8d4-af42-4972-9517-11ea256ea068"
  # Configuration options
}

resource "azurerm_resource_group" "myRG" {
  name     = "myResourceGroup"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "myVnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name
}

resource "azurerm_subnet" "mySubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.myRG.name
  virtual_network_name = azurerm_virtual_network.myVnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "myNIC" {
  name                = "myNIC"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name

  ip_configuration {
    name                          = "myNICConfiguration"
    subnet_id                     = azurerm_subnet.mySubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myPublicIP.id
  }
}

resource "azurerm_public_ip" "myPublicIP" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "myNSG" {
  name                = "myNSG"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "myNSGAssociation" {
  network_interface_id      = azurerm_network_interface.myNIC.id
  network_security_group_id = azurerm_network_security_group.myNSG.id
}

resource "azurerm_linux_virtual_machine" "myVM" {
  name                = "myVM"
  resource_group_name = azurerm_resource_group.myRG.name
  location            = azurerm_resource_group.myRG.location
  size                = "Standard_d2s_v5"
  admin_username      = "adminuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.myNIC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}
