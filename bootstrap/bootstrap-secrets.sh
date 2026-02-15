#!/usr/bin/env bash
set -euo pipefail

# Bootstrap secrets for 1Password Connect and External Secrets Operator.
# Run this AFTER the cluster exists but BEFORE ArgoCD syncs the apps.
#
# Required:
#   OP_CREDENTIALS_FILE  — path to 1password-credentials.json
#   OP_CONNECT_TOKEN     — 1Password Connect access token

if [[ -z "${OP_CREDENTIALS_FILE:-}" ]]; then
  echo "ERROR: OP_CREDENTIALS_FILE is not set" >&2
  exit 1
fi

if [[ ! -f "$OP_CREDENTIALS_FILE" ]]; then
  echo "ERROR: OP_CREDENTIALS_FILE does not exist: $OP_CREDENTIALS_FILE" >&2
  exit 1
fi

if [[ -z "${OP_CONNECT_TOKEN:-}" ]]; then
  echo "ERROR: OP_CONNECT_TOKEN is not set" >&2
  exit 1
fi

echo "==> Creating onepassword-connect namespace"
kubectl create namespace onepassword-connect --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating op-credentials secret"
kubectl create secret generic op-credentials \
  --namespace onepassword-connect \
  --from-file=1password-credentials.json="$OP_CREDENTIALS_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating external-secrets namespace"
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating onepassword-connect-token secret"
kubectl create secret generic onepassword-connect-token \
  --namespace external-secrets \
  --from-literal=token="$OP_CONNECT_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "==> Secrets bootstrapped successfully"
echo "    - op-credentials in onepassword-connect"
echo "    - onepassword-connect-token in external-secrets"
