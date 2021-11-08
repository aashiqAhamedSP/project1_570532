terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.83.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "3d736b00-44a4-4897-b211-a9178d4b0ed5"
  client_id       = "5203c43c-dba2-4cd7-9481-055313737721"
  client_secret   = "oTp7Q~ZCB2CfiL6x8lX2GD4ISzDbE0U9S8FgY"
  tenant_id       = "9ec05b9b-2f27-413a-a9ae-0a2f2cb9a059"
}

resource "azurerm_resource_group" "jenkins_rg" {
  name     = var.rgname
  location = var.rgloc
}

resource "azurerm_virtual_network" "jenkins_vnet" {
  name                = var.vnetname
  location            = azurerm_resource_group.jenkins_rg.location
  resource_group_name = azurerm_resource_group.jenkins_rg.name
  address_space       = ["10.1.0.0/16"]

}
resource "azurerm_subnet" "subnet1" {
  name                 = var.subnetname
  resource_group_name  = azurerm_resource_group.jenkins_rg.name
  virtual_network_name = azurerm_virtual_network.jenkins_vnet.name
  address_prefixes     = ["10.1.0.0/24"]

}

resource "azurerm_network_security_group" "nsg" {
  
  name                = "nsg"
  location            = azurerm_resource_group.jenkins_rg.location
  resource_group_name = azurerm_resource_group.jenkins_rg.name
}
resource "azurerm_network_security_rule" "ssh-rule" {
  
  name                        = "ssh"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.jenkins_rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "NSG_SUB_ASC" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pubip" {
  count = 2
  name                = "pubip${var.jnkscltr[count.index]}"
  resource_group_name = azurerm_resource_group.jenkins_rg.name
  location            = azurerm_resource_group.jenkins_rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  count = 2
  name                = "nic${var.jnkscltr[count.index]}"
  location            = azurerm_resource_group.jenkins_rg.location
  resource_group_name = azurerm_resource_group.jenkins_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pubip.*.id, count.index)
  }
}

resource "azurerm_linux_virtual_machine" "jenkins_cluster" {
  count                           = 2
  name                            = "vm-${var.jnkscltr[count.index]}"
  resource_group_name             = azurerm_resource_group.jenkins_rg.name
  location                        = azurerm_resource_group.jenkins_rg.location
  size                            = var.vmsize
  admin_username                  = var.uname
  admin_password                  = var.ps
  disable_password_authentication = false

  network_interface_ids = [
    element(azurerm_network_interface.nic.*.id, count.index)
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
}

resource "null_resource" "jenkins-cluster" {


  provisioner "file" {
    source      = "prepmaster.sh"
    destination = "/home/vmadmin/prep.sh"
    connection {
      host     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.public_ip_address, 0)
      user     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_username, 0)
      password = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_password, 0)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/vmadmin/prep.sh",
      "/home/vmadmin/prep.sh"
    ]
    connection {
      host     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.public_ip_address, 0)
      user     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_username, 0)
      password = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_password, 0)
    }
  }



  provisioner "file" {
    source      = "prepbldsrv.sh"
    destination = "/home/vmadmin/prep.sh"
    connection {
      host     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.public_ip_address, 1)
      user     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_username, 1)
      password = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_password, 1)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/vmadmin/prep.sh",
      "/home/vmadmin/prep.sh"
    ]

    connection {
      host     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.public_ip_address, 1)
      user     = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_username, 1)
      password = element(azurerm_linux_virtual_machine.jenkins_cluster.*.admin_password, 1)
    }
  }

}
output "vm_pub_ip1" {
  value = element(azurerm_public_ip.pubip.*.ip_address, 0)

}

output "vm_pub_ip2" {
  value = element(azurerm_public_ip.pubip.*.ip_address, 1)

}