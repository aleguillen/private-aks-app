terraform {
  required_version = ">= 0.12" 
  
  required_providers {
    azurerm  = "~> 2.8"
    template = "~> 2.1"
    tls = "~> 2.1"
  }
  backend "azurerm" {} # Comment this line if executing locally
}

provider "azurerm" {
  features {}
}