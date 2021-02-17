#!/usr/bin/env bash

set -o xtrace
set -e

set -o allexport
. ./.env
set +o allexport

which terraform || exit
which gcloud || exit
which kubectl || exit
which http || exit
which helm || exit
which fluxctl || exit

terraform destroy -auto-approve

# Undelete endpoints services
find openapi/ -type f -name "*.yaml" -exec sh -c 'gcloud --project $PROJECT_ID endpoints services undelete "$(yq -r '.host' $1)"' - {} \;

terraform apply -auto-approve

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
function wait_for_ip() {
  ip=""
  while [ -z "$ip" ]; do
    echo "Waiting for external IP on $1:$2"
    ip=$(kubectl get --namespace $1 $2 --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$ip" ] && sleep 10
  done
  echo "IP: $ip"
}

wait_for_ip cloud-endpoints svc/esp-echo
wait_for_ip prod svc/auth-proxy
wait_for_ip prod svc/payments-api

sleep 10

# Get jwt token
sign_in_headers=$(echo "{\"email\": \"$VAVATO_USER\", \"password\": \"$VAVATO_PASS\"}" | http https://api.vavato.com//auth/sign_in --headers | sed 1d)
uid=$(echo "$sign_in_headers" | yq -r '.uid')
access_token=$(echo "$sign_in_headers" | yq -r '."access-token"')
client=$(echo "$sign_in_headers" | yq -r '.client')
TOKEN=$(http post http://auth-proxy-api.vavato.com/auth/issue_token "client: $client" "access-token: $access_token" "uid: $uid" | jq -r '.access_token')

# Test endpoints
echo '{"message":"Vavato rocks!"}' | http https://echo-api.vavato.com/echo "Authorization: Bearer $TOKEN"
http https://payments-api.vavato.com/health_check "Authorization: Bearer $TOKEN"
http https://auth-proxy-api.vavato.com/auth/jwks
