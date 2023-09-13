data "azurerm_client_config" "current" {}
data azurerm_subscription "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-${var.region_key}-${var.resource_groups}-rg"
  location = var.region
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${var.project_name}-${var.environment}-${var.region_key}-${var.solution}-sa"
  resource_group_name      = "${var.project_name}-${var.environment}-${var.region_key}-${var.resource_groups}-rg"
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-${var.environment}-${var.region}-vnet"
  address_space       = var.address_space
  location            = var.region  #  region
  resource_group_name = "${var.project_name}-${var.environment}-${var.region}"
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "${var.project_name}-${var.environment}-${var.region}-app-subnet"
  resource_group_name  = "${var.project_name}-${var.environment}-${var.region}-rg"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes      = var.address_prefixes  #  subnet CIDR
}

resource "azurerm_function_app" "linux_function_app" {
    name                = "${var.project_name}-${var.environment}-${var.region_key}-${var.solution}-linux"
    resource_group_name = "${var.project_name}-${var.environment}-${var.region_key}-${var.resource_groups}-rg"
    location            = var.region
    app_service_plan_id = var.app_service_plan_id 
      storage_connection_string = azurerm_storage_account.storage_account.primary_connection_string
  version                   = "~3"
  os_type                   = "Linux"
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "AzureWebJobsStorage"     = azurerm_storage_account.storage_account.primary_connection_string
  }
}

resource "azurerm_app_service_plan" "app_service" {
  name                = "${var.project_name}${var.environment}${var.region_key}${var.solution}rg-${var.app_service_variables}"
  location            = var.region
  resource_group_name = "${var.project_name}-${var.environment}-${var.region_key}-${var.resource_groups}-rg"
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
}
}

resource "azurerm_storage_container" "container" {
  name                  = "${var.project_name}${var.environment}${var.region_key}${var.solution}-container"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "azurerm_function_app_blob_trigger" "trigger" {
  function_app_id = azurerm_function_app.linux_function_app.id
  container_name  = azurerm_storage_container.container.name
}

resource "azurerm_sql_server" "database_server" {
  name                         = "${var.project_name}-${var.environment}-${var.region}-database-server"
  resource_group_name          = "${var.project_name}-${var.environment}-${var.region}-rg"
  location                     = var.region
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
}
resource "azurerm_sql_database" "database" {
  name                         = "${var.project_name}-${var.environment}-${var.region}-db"
  resource_group_name          = "${var.project_name}-${var.environment}-${var.region}-rg"
  location                     = var.region
  server_name                  = azurerm_sql_server.database_server.name
  edition                      = "Basic"
  requested_service_objective_name = "Basic"
  collation                    = "SQL_Latin1_General_CP1_CI_AS"
}
