# acs-email-rbac/outputs.tf

output "role_assignment_ids" {
  description = "Map of service name to role assignment resource ID for each Container App managed identity granted ACS Email Sender."
  value       = { for k, v in azurerm_role_assignment.acs_email_sender : k => v.id }
}

output "role_assignment_principal_ids" {
  description = "Map of service name to principal ID confirmed in each role assignment — useful for audit/verification."
  value       = { for k, v in azurerm_role_assignment.acs_email_sender : k => v.principal_id }
}
