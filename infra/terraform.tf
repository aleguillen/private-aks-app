terraform {
  required_version = ">= 0.12" 
  
  required_providers {
    azurerm  = "~> 2.11.0"
    null     = "~> 2.1.2"
    random   = "~> 2.2.1"
  }

  backend "azurerm" {} # Comment this line if executing locally
}

provider "azurerm" {
    features {}
}