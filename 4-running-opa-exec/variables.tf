variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources."
  default = {
    "environment" = "dev"
    "purpose"     = "opa"
  }
}

variable "location" {
  type        = string
  description = "Location/region where the resources will be created."
  default     = "West US"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create."
  default     = "opa-test"
}

variable "vnet_address_space" {
  type        = string
  description = "CIDR block for the virtual network."
  default     = "10.0.0.0/16"
}

variable "subnets" {
  type        = map(string)
  description = "List of subnets to create."
  default = {
    subnet1 = "10.0.0.0/24"
    subnet2 = "10.0.1.0/24"
  }
}