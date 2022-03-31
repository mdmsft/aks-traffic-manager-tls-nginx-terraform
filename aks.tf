locals {
  network_contributor_role_assignment_scopes = [
    azurerm_subnet.aks_default.id,
    azurerm_subnet.aks_main.id,
    azurerm_public_ip.main.id
  ]
}

resource "azurerm_public_ip" "main" {
  name                = "pip-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.project}-${var.environment}"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                              = "aks-${local.resource_suffix}"
  location                          = var.location
  resource_group_name               = azurerm_resource_group.main.name
  dns_prefix                        = local.context_name
  automatic_channel_upgrade         = var.kubernetes_cluster_automatic_channel_upgrade
  kubernetes_version                = var.kubernetes_version
  role_based_access_control_enabled = true
  local_account_disabled            = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                         = "default"
    vm_size                      = var.kubernetes_cluster_default_node_pool_vm_size
    enable_auto_scaling          = true
    min_count                    = var.kubernetes_cluster_default_node_pool_min_count
    max_count                    = var.kubernetes_cluster_default_node_pool_max_count
    max_pods                     = var.kubernetes_cluster_default_node_pool_max_pods
    os_disk_size_gb              = var.kubernetes_cluster_default_node_pool_os_disk_size_gb
    os_sku                       = var.kubernetes_cluster_default_node_pool_os_sku
    only_critical_addons_enabled = true
    vnet_subnet_id               = azurerm_subnet.aks_default.id
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"

    load_balancer_profile {
      outbound_ip_address_ids = [
        azurerm_public_ip.main.id
      ]
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "main" {
  name                  = "main"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.kubernetes_cluster_main_node_pool_vm_size
  enable_auto_scaling   = true
  min_count             = var.kubernetes_cluster_main_node_pool_min_count
  max_count             = var.kubernetes_cluster_main_node_pool_max_count
  max_pods              = var.kubernetes_cluster_main_node_pool_max_pods
  os_disk_size_gb       = var.kubernetes_cluster_main_node_pool_os_disk_size_gb
  os_sku                = var.kubernetes_cluster_main_node_pool_os_sku
  vnet_subnet_id        = azurerm_subnet.aks_main.id

  upgrade_settings {
    max_surge = "100%"
  }
}

resource "azurerm_role_assignment" "aks_rbac_reader" {
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.main.id
  principal_id         = data.azurerm_client_config.main.object_id
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  count                = length(local.network_contributor_role_assignment_scopes)
  role_definition_name = "Network Contributor"
  scope                = local.network_contributor_role_assignment_scopes[count.index]
  principal_id         = azurerm_kubernetes_cluster.main.identity.0.principal_id
}
