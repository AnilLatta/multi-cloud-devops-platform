terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "ril-enterprise-multicloud-azure-rg"
  location = var.azure_region

  tags = {
    Environment = "prod"
    Cloud       = "Azure"
    ManagedBy   = "Terraform"
    Owner       = "Anil Kumar"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ril-enterprise-azure-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.60.0.0/16"]

  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-multicloud-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "ril-enterprise-aks-multicloud"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "ril-multicloud-aks"

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D4s_v5"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.rg.tags
}
