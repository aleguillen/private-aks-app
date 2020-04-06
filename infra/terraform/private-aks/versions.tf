terraform {
  required_version = ">= 0.12" 
  backend "azurerm" {
      storage_account_name = "__terraformstorageaccount__"
      container_name       = "terraform"
      key                  = "terraform.tfstate"
      access_key  ="__storagekey__"
  }
}

provider "azurerm" {
  version = "= 1.44"
}
