#!/usr/bin/env bash

set -o xtrace

# Probably shouldn't be exported
export GH_USER="tonsv2"
export GH_REPO="git@github.com:vavato-be/gitops-test-andreas.git"

which terraform || exit
which gcloud || exit
which pip || exit
which kubectl || exit
which http || exit
which helm || exit
which fluxctl || exit

terraform destroy -auto-approve

# Undelete endpoints services
find openapi/ -type f -name "*.yaml" -exec sh -c 'gcloud endpoints services undelete "$(yq -r '.host' $1)"' - {} \;

# Generate private and public keys
(
  cd scripts/keys || exit
  ./gen_keys.sh
)

# Generate jwks
(
  cd scripts/jwks || exit
  rm -rf venv/ __pycache__/
  virtualenv venv
  source venv/bin/activate
  pip install -r requirements.txt
  ./jwks.py ../keys/jwt-key.pub >jwks.json
  deactivate
)

terraform apply -auto-approve

curl --fail "$(terraform output -raw pub-key)" || exit

# Kubectl configuration
gcloud container clusters get-credentials vavato-website-terraform --region europe-west1


## Deployment should be kept separate but is included here for ease of testing
# Deploy echo
(
  cd ../ruby-docs-samples/endpoints/getting-started/ || exit
  kubectl create namespace cloud-endpoints
  kubectl apply --namespace cloud-endpoints -f deployment.yaml
)

# Get bearer token
cd scripts/token/ || exit
rm -rf venv/ __pycache__/
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
TOKEN=$(./get_token.py)
deactivate
cd - || exit

# Request
# sleep until external ip is assigned
ip=""
while [ -z "$ip" ]; do
  echo "Waiting for external IP"
  ip=$(kubectl get --namespace cloud-endpoints svc/esp-echo --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$ip" ] && sleep 1
done
echo "IP: $ip"

sleep 3
echo '{"message":"Vavato rocks!"}' | http --verify=no https://echo.api.vavato.com/echo "Authorization: Bearer $TOKEN"
