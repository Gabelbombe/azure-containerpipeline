variable "default_user" {}
variable "default_password" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "tfdemo" {
  name     = "RemoveTerraform"
  location = "US West"
}

resource "azurerm_virtual_network" "tfdemo" {
  name                = "AccountVNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = "US West"
  resource_group_name = "${azurerm_resource_group.tfdemo.name}"
}

resource "azurerm_subnet" "tfdemo" {
  name                 = "AccountSubnet"
  resource_group_name  = "${azurerm_resource_group.tfdemo.name}"
  virtual_network_name = "${azurerm_virtual_network.tfdemo.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "tfdemo" {
  name                         = "AccountPubIP"
  location                     = "US West"
  resource_group_name          = "${azurerm_resource_group.tfdemo.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "terralinux"

  tags {
    environment = "demo"
  }
}

resource "azurerm_network_interface" "tfdemo" {
  name                = "AccountInterface"
  location            = "US West"
  resource_group_name = "${azurerm_resource_group.tfdemo.name}"

  ip_configuration {
    name                          = "DemoConfiguration"
    subnet_id                     = "${azurerm_subnet.tfdemo.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.tfdemo.id}"
  }
}

resource "azurerm_storage_account" "tfdemo" {
  name                = "Account1982EC"
  resource_group_name = "${azurerm_resource_group.tfdemo.name}"
  location            = "US West"
  account_type        = "Standard_LRS"

  tags {
    environment = "demo"
  }
}

resource "azurerm_storage_container" "tfdemo" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.tfdemo.name}"
  storage_account_name  = "${azurerm_storage_account.tfdemo.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "tfdemo" {
  name                  = "TFVM02"
  location              = "US West"
  resource_group_name   = "${azurerm_resource_group.tfdemo.name}"
  network_interface_ids = ["${azurerm_network_interface.tfdemo.id}"]
  vm_size               = "Standard_A0"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "14.04.2-LTS"
    version   = "latfdemo"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.tfdemo.primary_blob_endpoint}${azurerm_storage_container.tfdemo.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "TFDemo"
    admin_username = "${var.default_user}"
    admin_password = "${var.default_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
