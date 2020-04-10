terraform {
  required_version = ">= 0.12" 
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}