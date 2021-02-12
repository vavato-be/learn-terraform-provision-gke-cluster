#!/usr/bin/env bash

set -o xtrace
set -e

# TODO: Import using source
#PROJECT_ID=cloud-dev-304205
PROJECT_ID=vavato-website
GH_USER="tonsv2"
GH_REPO="git@github.com:vavato-be/gitops-test-andreas.git"

which terraform || exit
which gcloud || exit
which pip || exit
which kubectl || exit
which http || exit
which helm || exit
which fluxctl || exit

terraform destroy -auto-approve

# Undelete endpoints services
find openapi/ -type f -name "*.yaml" -exec sh -c 'gcloud --project $PROJECT_ID endpoints services undelete "$(yq -r '.host' $1)"' - {} \;

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
gcloud --project $PROJECT_ID container clusters get-credentials "$(terraform output -raw cluster_name)" --region "$(terraform output -raw region)"

## Deployment should be kept separate but is included here for ease of testing
# Flux
kubectl create namespace flux

fluxctl install \
  --git-user=$GH_USER \
  --git-email=$GH_USER@users.noreply.github.com \
  --git-url=$GH_REPO \
  --git-path=namespaces,workloads,releases \
  --namespace=flux | kubectl apply -f -

helm upgrade -i helm-operator fluxcd/helm-operator --namespace flux --set helm.versions=v3

sleep 15
fluxctl identity --k8s-fwd-ns flux

read -p "Add the above key... GitHub -> Settings -> Deploy keys"

fluxctl sync --k8s-fwd-ns flux

# Request
# sleep until external ip is assigned
# TODO: Don't loop forever, only do x tries
sleep 10
ip=""
while [ -z "$ip" ]; do
  echo "Waiting for external IP"
  ip=$(kubectl get --namespace cloud-endpoints svc/esp-echo --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$ip" ] && sleep 1
done
echo "IP: $ip"

# Get bearer token
cd scripts/token/ || exit
rm -rf venv/ __pycache__/
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
TOKEN=$(./get_token.py)
echo $TOKEN
deactivate
cd - || exit

sleep 5
echo '{"message":"Vavato rocks!"}' | http --verify=no https://echo.api.vavato.com/echo "Authorization: Bearer $TOKEN"
http --verify=no https://payments.api.vavato.com/health_check
