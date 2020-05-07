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

variable "ado_vmss_enabled" {
  type        = bool
  description = "If enabled will use a VMSS instead of single VM. Default is false: creates a single VM."
  default     = true
}

variable "ado_vm_size" {
  type        = string
  description = "Use a VMSS instead of single VM."
  default     = "Standard_DS1_v2"
}

variable "ado_vmss_instances" {
  type        = number
  description = "If using VMSS specified the number of instances for the VMSS. Default is 2."
  default     = 2
}

variable "ado_vm_username" {
  type        = string
  description = "The username for the Azure DevOps VM."
}

variable "ado_vm_password" {
  type        = string
  description = "The password for the Azure DevOps VM."
  default     = ""
}

variable "vm_image_id" {
  type        = string
  description = "The VM Image Id to use for the VM or VMSS."
  default     = ""
}

variable "vm_image_ref" {
  type        = map(string)
  description = "The VM Image Id to use for the VM or VMSS."
  default     = {}
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
  description = "Azure DevOps Pool Name. Default is Default Agent Pool (automatically created in Azure DevOps) "
  default = "Default"
}

variable "ado_subscription_ids" {
  type        = list(string)
  description = "List of Azure Subscription ids for role assigment."
  default = []
}

variable "ado_proxy_url" {
  type        = string
  description = "Specify proxy URL for Azure DevOps Self-Hosted Agent."
  default = ""
}

variable "ado_proxy_username" {
  type        = string
  description = "Specify proxy URL Username for Azure DevOps Self-Hosted Agent."
  default = ""
}

variable "ado_proxy_password" {
  type        = string
  description = "Specify proxy URL Password for Azure DevOps Self-Hosted Agent."
  default = ""
}

variable "ado_proxy_bypass_list" {
  type        = list(string)
  description = "Specify proxy bypass URLs (in ECMAScript syntax)."
  default = []
}