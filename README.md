# Hetzner K3s Cluster

K3s cluster on Hetzner Cloud with ArgoCD GitOps.

## Structure

```
cluster.yaml              # Hetzner K3s cluster config (hetzner-k3s tool)
flake.nix                 # Nix dev shell: hetzner-k3s, kubectl, k9s, helm
bootstrap/
  install.sh              # One-time ArgoCD bootstrap script
k8s/
  root-app.yaml           # Root app-of-apps (scans k8s/apps/)
  apps/
    argocd.yaml           # ArgoCD self-management (Helm chart + git values)
  values/
    argocd.yaml           # ArgoCD Helm values
```

## Setup

### 1. Create the cluster

```sh
export HCLOUD_TOKEN=your-token
hetzner-k3s create --config cluster.yaml
```

### 2. Bootstrap ArgoCD

Push the repo to GitHub first, then:

```sh
./bootstrap/install.sh
```

### 3. Access ArgoCD

```sh
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open http://localhost:8080 — the admin password is printed by the bootstrap script.

## Adding apps

1. Create `k8s/apps/my-app.yaml` (ArgoCD Application CRD)
2. Optionally add `k8s/values/my-app.yaml` (Helm values)
3. Push — ArgoCD detects the new file and syncs it automatically
