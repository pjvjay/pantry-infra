# pantry-infra

Terraform bootstrap for the
[pantry-platform](https://github.com/pjvjay/pantry-platform) GitOps demo.

Deliberately tiny — that's the point. In a GitOps setup, Terraform's job is
the **seed and the cloud-side resources**, not the workloads:

| Owner | Resources |
|---|---|
| **This repo (Terraform)** | `pantry-db-password` Key Vault entry · ArgoCD **root Application** |
| **[pantry-gitops](https://github.com/pjvjay/pantry-gitops) (ArgoCD)** | namespaces, ExternalSecrets, CNPG Postgres Cluster, Deployments, Services, Ingress, migration Job |
| **[lifeguide-infra](https://github.com/pjvjay/lifeguide-infra) (shared platform)** | AKS, ACR, ArgoCD itself, ingress-nginx, cert-manager, CNPG operator, External Secrets Operator + `ClusterSecretStore` |

Once `terraform apply` finishes, this stack is done: every subsequent change
to the running app flows through git commits to the other repos. Terraform
is never in the deploy loop.

## Apply

```bash
az login                       # cluster + Key Vault live in this subscription
az aks show -g rg-therealpj92-0374 -n lifeguide-dev-aks -o none  # cluster must be running

terraform init
terraform plan                 # expect: 2 to add (password + KV secret) + 1 manifest
terraform apply
```

> `kubernetes_manifest` validates against the live API server at plan time —
> the AKS cluster must be running (`make resume` in lifeguide-infra if it's
> stopped).

## What happens next

```
terraform apply
  └─ pantry-db-password → Key Vault
  └─ Application/pantry-root → argocd namespace
       └─ ArgoCD pulls pantry-gitops/argocd/
            ├─ AppProject pantry           (scoped repo/namespace/permissions)
            ├─ Application pantry-infra    → namespaces, secrets, Postgres
            └─ Application pantry-apps     → migrate Job, API, frontend, ingress
```

Watch it converge:

```bash
kubectl get applications -n argocd -w
kubectl get pods -n pantry-db -n pantry-app
```

Then: https://lifeguide-dev-67c717e5.canadacentral.cloudapp.azure.com/pantry/

## Teardown

```bash
terraform destroy
```

Deleting `pantry-root` cascades (the resources-finalizer) — ArgoCD prunes
every pantry resource it created, including the Postgres cluster and its PVC.
The shared platform is untouched.
