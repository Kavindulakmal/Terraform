/*Azure Virtual Private Cloud (VPC), subnets, and Ubuntu virtual machines using Terraform*/
provider "azurerm" {
  features {}
}

#Create a Resource Group
resource "azurerm_resource_group" "main" {
  name = "vpc_test"
  location = "East US"
}

#Create a Virtual Network (VPC)
resource "azurerm_virtual_network" "main" {
  name = "my_VPC"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

#Create Subnets
resource "azurerm_subnet" "subnet1" {
  name = "subnet1"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name = "subnet2"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.2.0/24"]
}

#Create network interfaces for the VMs
resource "azurerm_network_interface" "vm1_nic" {
  name = "vm1_nic"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "vm2_nic"{
  name = "vm2_nic"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create the Vms with a web server on port 3000

#VM1 
resource "azurerm_virtual_machine" "vm1" {
  name = "vm1"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.vm1_nic.id]
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
    name = "vm1-os-disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = 30
  }

  os_profile {
    computer_name = "vm1"
    admin_username = "azureuser"
    admin_password = "P@ssw0rd1234!"
    custom_data = <<-EOF
                    #!/bin/bash
                    apt-get update
                    apt-get install -y nodejs npm
                    echo "const http = require('http');" > app.js
                    echo "http.createServer((req, res) => {" >> app.js
                    echo "  res.writeHead(200, {'Content-Type': 'text/plain'});" >> app.js
                    echo "  res.end('Hello World');" >> app.js
                    echo "}).listen(3000);" >> app.js
                    echo "console.log('Server running on port 3000');" >> app.js
                    node app.js &
                    EOF
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

#VM2
resource "azurerm_virtual_machine" "vm2" {
  name                  = "vm2"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.vm2_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "vm2-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "vm2"
    admin_username = "azureuser"
    admin_password = "P@ssw0rd1234!"
    custom_data    = <<-EOF
                    #!/bin/bash
                    apt-get update
                    apt-get install -y nodejs npm
                    echo "const http = require('http');" > app.js
                    echo "http.createServer((req, res) => {" >> app.js
                    echo "  res.writeHead(200, {'Content-Type': 'text/plain'});" >> app.js
                    echo "  res.end('Hello World');" >> app.js
                    echo "}).listen(3000);" >> app.js
                    echo "console.log('Server running on port 3000');" >> app.js
                    node app.js &
                    EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    publisher = "Canonical"
    offer =  "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

#Create a public IP address for the load balancer
resource "azurerm_public_ip" "main" {
  name = "myPublicIP"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Static"
  sku = "Basic"
}

#Create the Load Balancer
resource "azurerm_lb" "main" {
  name = "MyLoadBalancer"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "Basic"
  frontend_ip_configuration {
    name = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Create a Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "name" {
  name = "myBackendPool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
}

# Create a Health Probe for port 3000
resource "azurerm_lb_probe" "main" {
  name                = "myHealthProbe"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Tcp"
  port                = 3000
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Create a Load Balancing Rule for port 3000
resource "azurerm_lb_rule" "main" {
  name                            = "myLBRule"
  resource_group_name             = azurerm_resource_group.main.name
  loadbalancer_id                 = azurerm_lb.main.id
  protocol                        = "Tcp"
  frontend_port                   = 3000
  backend_port                    = 3000
  frontend_ip_configuration_name  = "PublicIPAddress"
  backend_address_pool_id         = azurerm_lb_backend_address_pool.main.id
  probe_id                        = azurerm_lb_probe.main.id
}

# Associate the VMs with the Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "vm1" {
  network_interface_id            = azurerm_network_interface.vm1_nic.id
  ip_configuration_name           = "internal"
  backend_address_pool_id         = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm2" {
  network_interface_id            = azurerm_network_interface.vm2_nic.id
  ip_configuration_name           = "internal"
  backend_address_pool_id         = azurerm_lb_backend_address_pool.main.id
}