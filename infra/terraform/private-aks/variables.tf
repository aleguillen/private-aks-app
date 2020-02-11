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

variable "aks_service_principal_client_id" {
  type        = string
  description = "The Client ID for the Service Principal."
}

variable "aks_service_principal_client_secret" {
  type        = string
  description = "The Client Secret for the Service Principal."
}

variable "ado_subnet_id" {
  type        = string
  description = "The Subnet ID for the Azure DevOps Self Agent."
}

# variable "bastion_subnet_id" {
#   type        = string
#   description = "The Subnet ID for the Private Endpoint."
# }
