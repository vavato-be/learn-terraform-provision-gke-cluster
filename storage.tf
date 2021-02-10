resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.object.output_name
  bucket = google_storage_bucket.bucket.name
  role = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket" "bucket" {
  name = "cloud-endpoints-auth-key"
  location = "EU"
  force_destroy = true
}

resource "google_storage_bucket_object" "object" {
# TODO: Doesn't work... "Error creating ObjectAccessControl: googleapi: got HTTP response code 404 with body: Not Found"
#  name = "keys/jwt-key.pub"

  name = "jwks.json"
  bucket = google_storage_bucket.bucket.name
  source = "scripts/jwks/jwks.json"
}
