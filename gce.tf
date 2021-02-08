resource "google_endpoints_service" "echo_service" {
  service_name = "echo.api.vavato.com"
  project = var.project_id
  openapi_config = file("openapi/echo.yaml")
}

resource "google_endpoints_service" "payments_service" {
  service_name = "payments.api.vavato.com"
  project = var.project_id
  openapi_config = file("openapi/payments.yaml")
}
