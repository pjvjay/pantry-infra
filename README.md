# pantry-infra

Terraform bootstrap for the
[pantry-platform](https://github.com/pjvjay/pantry-platform) GitOps demo.

Deliberately tiny — that's the point. In a GitOps setup, Terraform's job is
the **seed and the cloud-side resources**, not the workloads:

| Owner | Resources |
|---|---|
| **This repo (Terraform)** | `pantry-db-password` Key Vault entry · ArgoCD **root Application** |
| **[pantry-gitops](https://github.com/pjvjay/pantry-gitops) (ArgoCD)** | namespaces, ExternalSecrets, CNPG Postgres Cluster, Deployments, Services, Ingress, migration Job |

Once `terraform apply` finishes, this stack is done: every subsequent change
to the running app flows through git commits to the other repos. Terraform
is never in the deploy loop.

## Platform prerequisites (bring your own cluster)

This stack targets **any existing AKS cluster** that runs the standard
platform layer — it references the cluster via data sources and never
mutates it. Required on the cluster before applying:

- **ArgoCD** (the root Application lands in the `argocd` namespace)
- **ingress-nginx** + **cert-manager** with a `ClusterIssuer` named
  `letsencrypt-prod`
- **CloudNativePG operator** (cluster-wide)
- **External Secrets Operator** with a `ClusterSecretStore` named
  `azure-key-vault` pointing at the Key Vault you pass in, and an
  `anthropic-api-key` secret present in that vault

Any cluster satisfying that contract works — the pantry stack has no
dependency on any particular cluster or project.

## Apply

```bash
az login
cp terraform.tfvars.example terraform.tfvars   # fill in your subscription/RG/AKS/KV

terraform init
terraform plan     # expect: 2 to add (password + KV secret) + 1 manifest
terraform apply
```

> `kubernetes_manifest` validates against the live API server at plan time —
> the AKS cluster must be running.

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

Then: `https://<your-cluster-ingress-host>/pantry/` (set the host in
`pantry-gitops/apps/pantry-ingress/`).

## Teardown

```bash
terraform destroy
```

Deleting `pantry-root` cascades (the resources-finalizer) — ArgoCD prunes
every pantry resource it created, including the Postgres cluster and its PVC.
The platform layer is untouched.
