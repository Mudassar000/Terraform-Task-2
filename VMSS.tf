resource "azurerm_network_security_group" "NSG" {
  count               = length(var.location)
  name                = "NSG-${count.index}"
  location            = element(azurerm_resource_group.RG.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)

  #Add rule for Inbound Access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "corporate-production-nsg-assoc" {
  count                     = length(var.location)
  subnet_id                 = element(azurerm_subnet.subnet.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.NSG.*.id, count.index)
}


resource "azurerm_linux_virtual_machine_scale_set" "VMSS" {
  count               = length(var.location)
  name                = "vmscaleset-${count.index}"
  location            = element(azurerm_resource_group.RG.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)
  upgrade_mode        = "Manual"
  sku                 = "Standard_B2s"
  instances           = 1
  admin_username      = "adminuser"


  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = local.first_public_key
  }

  network_interface {
    name                          = "RG"
    primary                       = true
    enable_ip_forwarding          = true
    enable_accelerated_networking = true
    network_security_group_id     = element(azurerm_network_security_group.NSG.*.id, count.index)

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = element(azurerm_subnet.subnet.*.id, count.index)
      load_balancer_backend_address_pool_ids = [element(azurerm_lb_backend_address_pool.BackEndAddressPool.*.id, count.index)]
    }
  }
}