variable "prefix" {
  type        = string
  description = "The prefix for all your resources. Ex.: <prefix>-rg, <prefix>-vnet"
}

variable "environment_name" {
  type        = string
  description = "Environment Name."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where your resources will be created."
}

variable "bastion_vm_username" {
  type        = string
  description = "The username for the Bastion VM."
}

variable "bastion_vm_password" {
  type        = string
  description = "The password for the Bastion VM."
}

variable "ado_vm_username" {
  type        = string
  description = "The username for the Azure DevOps VM."
}

variable "ado_vm_password" {
  type        = string
  description = "The password for the Azure DevOps VM."
}

variable "ado_server_url" {
  type        = string
  description = "Azure DevOps Server URL."
}

variable "ado_pat_token" {
  type        = string
  description = "Azure DevOps PAT token."
}

variable "ado_pool_name" {
  type        = string
  description = "Azure DevOps Pool Name."
  default = "default"
}
