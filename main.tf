#Configure the Azure Provider
provider "azurerm" {
  features {}
}

#Create a Resource Group
resource "azurerm_resource_group" "test-resource" {
  name = "test-resource"
  location = "East US"
}