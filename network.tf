resource "azurerm_resource_group" "RG" {
  count    = length(var.location)
  name     = "rgmudassar-${count.index}"
  location = element(var.location, count.index)
}

resource "azurerm_virtual_network" "vnet" {
  count               = length(var.location)
  name                = "vnet-${count.index}"
  resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)
  address_space       = [element(var.vnet_address_space, count.index)]
  location            = element(azurerm_resource_group.RG.*.location, count.index)
}

resource "azurerm_subnet" "subnet" {
  count                = length(var.location)
  name                 = "subnet"
  resource_group_name  = element(azurerm_resource_group.RG.*.name, count.index)
  virtual_network_name = element(azurerm_virtual_network.vnet.*.name, count.index)
  address_prefixes = [cidrsubnet(
  element(azurerm_virtual_network.vnet[count.index].address_space, count.index, ), 8, 0, )]
}

# enable global peering between the two virtual network
resource "azurerm_virtual_network_peering" "peering" {
  count                        = length(var.location)
  name                         = "peering-to-${element(azurerm_virtual_network.vnet.*.name, 1 - count.index)}"
  resource_group_name          = element(azurerm_resource_group.RG.*.name, count.index)
  virtual_network_name         = element(azurerm_virtual_network.vnet.*.name, count.index)
  remote_virtual_network_id    = element(azurerm_virtual_network.vnet.*.id, 1 - count.index)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
}

resource "azurerm_network_interface" "NIC" {
  count               = length(var.location)
  name                = "NIC-${count.index}"
  location            = element(azurerm_resource_group.RG.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)

  ip_configuration {
    name                          = "ipconfig-${count.index}"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, count.index)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_string" "fqdn" {
  count   = length(var.location)
  length  = 6
  special = false
  upper   = false
  numeric = false
}

resource "azurerm_public_ip" "PIP" {
  count               = length(var.location)
  name                = "PIP-${count.index}"
  location            = element(azurerm_resource_group.RG.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.RG.*.name, count.index)
  allocation_method   = "Static"
  domain_name_label   = element(random_string.fqdn.*.result, count.index)
}