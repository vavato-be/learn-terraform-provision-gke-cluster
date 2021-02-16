# TODO
* create dedicated service account
* Rotate keys
  https://auth0.com/docs/tokens/json-web-tokens/json-web-key-sets

# jwks.json
* Properties - https://auth0.com/docs/tokens/json-web-tokens/json-web-key-set-properties
* Example - https://tools.ietf.org/html/rfc7517#appendix-A.1
* Find modulus - https://crypto.stackexchange.com/questions/18031/how-to-find-modulus-from-a-rsa-public-key/18034#18034?newreg=c8b488b47bae44e8935a089d6690306d

# Learn Terraform - Provision a GKE Cluster

This repo is a companion repo to the [Provision a GKE Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster), containing Terraform configuration files to provision an GKE cluster on GCP.

This sample repo also creates a VPC and subnet for the GKE cluster. This is not
required but highly recommended to keep your GKE cluster isolated.
