resource "azurerm_lb" "LB" {
  count               = length(var.location)
  name                = "LoadBalancer-${count.index}"
  location            = element(azurerm_resource_group.RG.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "PublicIPAddressFrontEnd"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, count.index)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_rule" "LBrule" {
  count           = length(var.location)
  loadbalancer_id = element(azurerm_lb.LB.*.id, count.index)
  #   resource_group_name            = element(azurerm_resource_group.RG.*.name, count.index)
  name                           = "ssh-inbound-rule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddressFrontEnd"
  probe_id                       = element(azurerm_lb_probe.lbprobe.*.id, count.index)
  backend_address_pool_ids       = [element(azurerm_lb_backend_address_pool.BackEndAddressPool.*.id, count.index)]
}

resource "azurerm_lb_backend_address_pool" "BackEndAddressPool" {
  count = length(var.location)
  # resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)
  loadbalancer_id = element(azurerm_lb.LB.*.id, count.index)
  name            = "BackEndAddressPool-${count.index}"
}

resource "azurerm_lb_probe" "lbprobe" {
  count = length(var.location)
  #   resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)
  loadbalancer_id = element(azurerm_lb.LB.*.id, count.index)
  name            = "ssh-inbound-probe"
  port            = 22
}

resource "azurerm_network_interface_backend_address_pool_association" "NICbackendAssociation" {
  count                   = 2
  network_interface_id    = element(azurerm_network_interface.NIC.*.id, count.index)
  ip_configuration_name   = "ipconfig-${count.index}"
  backend_address_pool_id = element(azurerm_lb_backend_address_pool.BackEndAddressPool.*.id, count.index)
}