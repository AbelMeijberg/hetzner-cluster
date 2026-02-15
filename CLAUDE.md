# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hetzner K3s cluster infrastructure managed via GitOps with ArgoCD. The cluster runs on Hetzner Cloud with 3 master nodes (cx23) and 2 worker nodes (cx33) in Nuremberg, using K3s v1.32.12 with etcd datastore.

## Architecture

### GitOps App-of-Apps Pattern

ArgoCD manages all cluster applications through a root application that scans `k8s/apps/` for Application CRDs:

```
k8s/root-app.yaml (root app-of-apps)
└── k8s/apps/          ← ArgoCD auto-discovers Application CRDs here
    ├── argocd.yaml              (self-managing, Helm)
    ├── external-secrets.yaml    (Helm)
    ├── onepassword-connect.yaml (Helm)
    ├── tailscale-operator.yaml  (Helm + raw manifests)
    └── cluster-secret-store.yaml (raw manifests)
```

### Secret Management

1Password → 1Password Connect (in-cluster API) → External Secrets Operator → Kubernetes Secrets

The `ClusterSecretStore` named `onepassword` connects ESO to 1Password Connect. All application secrets must be managed through this chain — never create plain Kubernetes Secrets directly.

To give an app access to a secret stored in the 1Password "k8s" vault, create an `ExternalSecret` resource:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword
  target:
    name: <resulting-k8s-secret-name>
  data:
    - secretKey: <key-in-k8s-secret>
      remoteRef:
        key: <1password-item-name>
        property: <1password-field-name>
```

Place these in `k8s/manifests/<app-name>/` alongside other raw manifests for the app.

### Directory Layout

- `cluster.yaml` — Hetzner-k3s cluster definition (nodes, networking, addons)
- `k8s/apps/` — ArgoCD Application CRDs (what to deploy)
- `k8s/values/` — Helm values files (how to configure each app)
- `k8s/manifests/` — Raw Kubernetes manifests (non-Helm resources)
- `bootstrap/` — One-time setup scripts (run manually, not GitOps-managed)

## Common Commands

```bash
# Dev tools (kubectl, helm, k9s, hetzner-k3s) are automatically available
# via direnv + Nix when entering this directory

# Provision/update the Hetzner cluster
hetzner-k3s create --config cluster.yaml

# Bootstrap ArgoCD and root app (one-time)
bash bootstrap/install.sh

# Bootstrap secrets for 1Password/ESO (one-time, requires OP_CREDENTIALS_FILE and OP_CONNECT_TOKEN)
bash bootstrap/bootstrap-secrets.sh

# Check cluster status
kubectl get nodes
kubectl get applications -n argocd
```

## Adding a New Application

1. Create an Application CRD in `k8s/apps/<app-name>.yaml`
2. If Helm-based, add values in `k8s/values/<app-name>.yaml`
3. If manifest-based, add YAMLs in `k8s/manifests/<app-name>/`
4. Commit and push — ArgoCD auto-syncs (automated sync with pruning and self-healing enabled)

## Conventions

- All ArgoCD apps use `automated` sync policy with `prune: true` and `selfHeal: true`
- Helm chart versions are pinned to exact versions (e.g., `7.9.1`, `2.0.0`) — no wildcards
- Resource requests/limits are tuned for a small cluster — keep them conservative
- Helm apps use `ServerSideApply: true` and `CreateNamespace=true` sync options
- Repository reference: `https://github.com/AbelMeijberg/hetzner-cluster` (used in Application CRDs `repoURL`)
- Target revision: `master` branch
- **Never git commit directly** — always prompt the user to commit themselves
