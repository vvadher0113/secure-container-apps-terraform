output "resource_group_name" {
  description = "Name of the resource group holding the state storage account."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "State storage account name. Copy this value into infra/envs/dev/backend.tf."
  value       = azurerm_storage_account.state.name
}

output "storage_account_id" {
  description = "Resource ID of the state storage account."
  value       = azurerm_storage_account.state.id
}

output "container_name" {
  description = "Blob container name for state files."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_snippet" {
  description = "Ready-to-paste backend block for infra/envs/dev/backend.tf."
  value       = <<-EOT
    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.state.name}"
      storage_account_name = "${azurerm_storage_account.state.name}"
      container_name       = "${azurerm_storage_container.tfstate.name}"
      key                  = "envs/dev/terraform.tfstate"
      use_azuread_auth     = true
    }
  EOT
}
