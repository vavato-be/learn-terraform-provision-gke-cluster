variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

provider "google" {
  project = var.project_id
  region = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name = "${var.project_id}-subnet"
  region = var.region
  network = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

# Peering
variable "other-network" {
  default = "default"
}

data "google_compute_network" "other" {
  name = var.other-network
}

resource "google_compute_network_peering" "peering1" {
  name = "peering1-terraform"
  network = google_compute_network.vpc.id
  peer_network = data.google_compute_network.other.id

# TODO: Only do this if needed
  export_custom_routes = true
  export_subnet_routes_with_public_ip = true
}

resource "google_compute_network_peering" "peering2" {
  name = "peering2-terraform"
  network = data.google_compute_network.other.id
  peer_network = google_compute_network.vpc.id

# TODO: Only do this if needed
  import_custom_routes = true
  import_subnet_routes_with_public_ip = true
}
