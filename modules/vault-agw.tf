resource "azurerm_application_gateway" "demostack" {
  name                = "${var.resource_group}-awg"
  resource_group_name = "${azurerm_resource_group.demostack.name}"
  location            = "${var.location}"

  sku {
    name     = "Standard_Medium"
    tier     = "Standard"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway_ip"
    subnet_id = "${azurerm_virtual_network.awg.id}/subnets/${azurerm_subnet.awg.name}"
  }

  frontend_port {
    name = "gateway_http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend_ip"
    public_ip_address_id = "${azurerm_public_ip.awg.id}"
    
  }

  backend_address_pool {
    # name = "${azurerm_lb_backend_address_pool.lb.name}"
    name = "demostack-backend-pool"
  }

  http_listener {
    name                           = "vault_listener"
    frontend_ip_configuration_name = "frontend_ip"
    frontend_port_name             = "gateway_http"
    protocol                       = "Http"
  }

  probe {
    name                = "vault_health"
    protocol            = "https"
    path                = "/v1/sys/health"
    host                = "127.0.0.1"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "3"
  }

  backend_http_settings {
    name                  = "vault_backend"
    cookie_based_affinity = "Disabled"
    port                  = 8200
    protocol              = "Https"
    request_timeout       = 1
    probe_name            = "vault_health"
  }


  request_routing_rule {
    name                       = "vault_routing"
    rule_type                  = "Basic"
    http_listener_name         = "vault_listener"
    backend_address_pool_name  = "demostack-backend-pool"
    backend_http_settings_name = "vault_backend"
  }

  ssl_certificate {
    name = "test cert"
    data = "${tls_locally_signed_cert.awg.cert_pem}"
  }

    ssl_certificate {
    count      = "${var.servers}" 
    name = "demostack server ${count.index} "
    data = "${element(tls_locally_signed_cert.servers.*.cert_pem, count.index)}"
  }



}
