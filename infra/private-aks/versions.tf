terraform {
  required_version = ">= 0.12" 
  
  required_providers {
    azurerm  = "~> 2.7"
    null     = "~> 2.1"
    random   = "~> 2.2"
  }

  backend "azurerm" {} # Comment this line if executing locally
}

provider "azurerm" {
    features {}
}