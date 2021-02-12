output "region" {
  value = var.region
  description = "GCloud Region"
}

output "project_id" {
  value = var.project_id
  description = "GCloud Project ID"
}

output "cluster_name" {
  value = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "cluster_host" {
  value = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "configure-kubectl" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region}"
}

output "pub-key" {
  value = "https://storage.googleapis.com/${google_storage_bucket.bucket.name}/${google_storage_bucket_object.object.name}"
}
