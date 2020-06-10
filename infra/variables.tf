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

variable "common_tags" {
    type = map(string)
    description = "Common resources tags. Key-value pair"
    default = {}
}

variable "aks_service_principal_client_id" {
  type        = string
  description = "The Client ID of the Service Principal."
}

variable "aks_service_principal_client_secret" {
  type        = string
  description = "The Client Secret of the Service Principal."
}

variable "aks_service_principal_id" {
  type        = string
  description = "The ID of the Service Principal."
}

variable "aks_version" {
  type        = string
  description = "Version of Kubernetes specified when creating the AKS managed cluster."
}

variable "pe_rg_name" {
  type        = string
  description = "The Resource Group name for the Private Endpoint."
}

variable "pe_vnet_name" {
  type        = string
  description = "The VNET name for the Private Endpoint."
}

variable "pe_subnet_name" {
  type        = string
  description = "The Subnet name for the Private Endpoint."
}

variable "pe_is_manual_connection" {
  type        = string
  description = "Does the Private Endpoint request requires Manual Approval?."
  default = false
}

variable "pe_request_message" {
  type        = string
  description = "The Private Endpoint request message?."
  default = ""
}
