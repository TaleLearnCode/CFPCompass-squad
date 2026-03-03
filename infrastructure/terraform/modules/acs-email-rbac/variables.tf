# acs-email-rbac/variables.tf

variable "acs_resource_id" {
  description = "The resource ID of the Azure Communication Services resource to which RBAC roles will be assigned."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Communication/communicationServices/[^/]+$", var.acs_resource_id))
    error_message = "acs_resource_id must be a valid Azure Communication Services resource ID."
  }
}

variable "container_app_principal_ids" {
  description = "Map of service name to system-assigned managed identity principal ID for each Container App that requires ACS email sending access. Keys are used in role assignment names and descriptions."
  type        = map(string)

  validation {
    condition     = length(var.container_app_principal_ids) > 0
    error_message = "At least one Container App principal ID must be provided."
  }
}

variable "environment" {
  description = "Deployment environment. Used in role assignment names and descriptions."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}
