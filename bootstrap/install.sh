#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Adding ArgoCD Helm repo"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo

echo "==> Creating argocd namespace"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing ArgoCD via Helm"
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values "$REPO_DIR/k8s/values/argocd.yaml" \
  --version "7.*" \
  --wait \
  --timeout 5m

echo "==> Waiting for argocd-server to be ready"
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

ADMIN_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)

echo "==> Applying root app-of-apps"
kubectl apply -f "$REPO_DIR/k8s/root-app.yaml"

echo ""
echo "============================================"
echo "  ArgoCD bootstrap complete!"
echo "============================================"
echo ""
echo "  Admin password: $ADMIN_PASSWORD"
echo ""
echo "  Access the UI:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "    Open http://localhost:8080"
echo "    Login: admin / $ADMIN_PASSWORD"
echo ""
echo "  ArgoCD will now manage itself and any apps in k8s/apps/"
echo "============================================"
