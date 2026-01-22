provider "google" {
  project = var.project_id
}

locals {
  admin_pw = random_password.admin.result
  env_vars = merge(
    var.env_vars,
    length(lookup(var.env_vars, "admin_pw", "")) == 0 ? {
      admin_pw = local.admin_pw
    } : {}
  )
}

resource "google_compute_instance" "instance" {
  name         = "${var.goog_cm_deployment_name}-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["${var.goog_cm_deployment_name}-deployment"]

  boot_disk {
    device_name = "${var.goog_cm_deployment_name}-disk"

    initialize_params {
      size  = var.boot_disk_size
      type  = var.boot_disk_type
      image = var.source_image
    }
  }

  can_ip_forward = var.ip_forward

  network_interface {
    subnetwork = local.create_vpc ? google_compute_subnetwork.subnet[0].id : data.google_compute_subnetwork.existing_subnet[0].id

    access_config {}
  }

  metadata = local.env_vars

  metadata_startup_script = <<-EOF
    #!/bin/bash

    bash -c 'bash <(curl -fsS https://packages.openvpn.net/as/install.sh) --yes --as-version=3.0.2'
    apt-mark hold openvpn-as

    /usr/bin/ovpn-init --gcp --batch --force

    . /usr/local/openvpn_as/etc/VERSION

    sed -i 's#^\(OpenVPN Access Server Appliance \)\( .*\)#\1'"$AS_VERSION"' \\n \\l#g' /etc/issue
    sed -i 's#^\(echo "Welcome to OpenVPN Access Server Appliance \)\(.*\)#\1'"$AS_VERSION"'"#g' /etc/update-motd.d/00-header
  EOF
}

resource "google_compute_firewall" "tcp_443" {
  count = var.enable_tcp_443 ? 1 : 0

  name = "${var.goog_cm_deployment_name}-tcp-443"
  network = local.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing_vpc[0].name

  allow {
    ports = ["443"]
    protocol = "tcp"
  }

  source_ranges =  compact([for range in split(",", var.tcp_443_source_ranges) : trimspace(range)])

  target_tags = ["${var.goog_cm_deployment_name}-deployment"]
}

resource "google_compute_firewall" "tcp_943" {
  count = var.enable_tcp_943 ? 1 : 0

  name = "${var.goog_cm_deployment_name}-tcp-943"
  network = local.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing_vpc[0].name

  allow {
    ports = ["943"]
    protocol = "tcp"
  }

  source_ranges =  compact([for range in split(",", var.tcp_943_source_ranges) : trimspace(range)])

  target_tags = ["${var.goog_cm_deployment_name}-deployment"]
}

resource "google_compute_firewall" "udp_1194" {
  count = var.enable_udp_1194 ? 1 : 0

  name = "${var.goog_cm_deployment_name}-udp-1194"
  network = local.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing_vpc[0].name

  allow {
    ports = ["1194"]
    protocol = "udp"
  }

  source_ranges =  compact([for range in split(",", var.udp_1194_source_ranges) : trimspace(range)])

  target_tags = ["${var.goog_cm_deployment_name}-deployment"]
}

resource "google_compute_firewall" "tcp_22" {
  count = var.enable_tcp_22 ? 1 : 0

  name = "${var.goog_cm_deployment_name}-tcp-22"
  network = local.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing_vpc[0].name

  allow {
    ports = ["22"]
    protocol = "tcp"
  }

  source_ranges =  compact([for range in split(",", var.tcp_22_source_ranges) : trimspace(range)])

  target_tags = ["${var.goog_cm_deployment_name}-deployment"]
}

resource "random_password" "admin" {
  length = 12
  override_special = "!@#$%^&*()-_=+"
}
