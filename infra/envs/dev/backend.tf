terraform {
  backend "azurerm" {
    # Populate these values from the output of `terraform apply` in bootstrap/.
    # Then run: terraform init -reconfigure
    resource_group_name  = "rg-tfstate-contoso"
    storage_account_name = "stcontosostate01"
    container_name       = "tfstate"
    key                  = "envs/dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}
