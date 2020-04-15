terraform {
  required_version = ">= 0.12" 
  backend "azurerm" {} # Comment this line if executing locally
}

provider "azurerm" {
  features {}
}