provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "python-repo"
  format        = "DOCKER"
}

resource "google_container_cluster" "primary" {
  name     = "gke-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  # Use Standard cluster (not autopilot)
  networking_mode = "VPC_NATIVE"

  # Disable addons to save resources
  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = true
    }
  }

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = "e2-micro"

    # Spot instance (cheaper)
    spot = true

    # Minimal disk
    disk_size_gb = 10
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
