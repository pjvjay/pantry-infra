# pantry-infra

Terraform bootstrap for the
[pantry-platform](https://github.com/pjvjay/pantry-platform) GitOps demo.

Deliberately tiny — that's the point. In a GitOps setup, Terraform's job is
the **seed and the cloud-side resources**, not the workloads:

| Owner | Resources |
|---|---|
| **This repo (Terraform)** | `pantry-db-password` + `pantry-mcp-tokens` Key Vault entries · ArgoCD **root Application** |
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
terraform plan     # expect: 4 to add (2 random_password + 2 KV secrets) + 1 manifest
terraform apply
```

> `kubernetes_manifest` validates against the live API server at plan time —
> the AKS cluster must be running.

## What happens next

```
terraform apply
  └─ pantry-db-password → Key Vault
  └─ pantry-mcp-tokens  → Key Vault   (`terraform:<secret>`; ESO projects it into
  │                                     pantry-app as `pantry-mcp-credentials`,
  │                                     the API reads it as MCP_AUTH_TOKENS)
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

## Configure an MCP client

The MCP endpoint at `/pantry/api/mcp` requires a bearer token once
`pantry-mcp-tokens` is present. The Key Vault value is `label:secret`
(the label — `terraform` here — is what pantry-api records as the
submitter/reviewer on origin submissions); a client sends only the secret:

```bash
SECRET=$(az keyvault secret show --vault-name <kv> --name pantry-mcp-tokens \
           --query value -o tsv | tr ',' '\n' | awk -F: '$1=="terraform"{print $2}')
claude mcp add --transport http pantry-remote \
  https://<your-cluster-ingress-host>/pantry/api/mcp \
  --header "Authorization: Bearer $SECRET"
```

The pipeline selects the `terraform` entry by label, so it keeps working
once the value holds several `label:secret` entries.

To add a second client with its own audit label, append `,<label>:<secret>`
to the Key Vault value (outside Terraform, or by adding an entry here),
wait for ESO to re-sync the Secret (or force it with the `force-sync`
annotation), then roll the API so the new value reaches the process —
`MCP_AUTH_TOKENS` is an environment variable resolved at pod start, and
the API caches its configuration for the life of the process:

```bash
kubectl rollout restart deployment/pantry-api -n pantry-app
```

Apply this Terraform **before** merging the pantry-gitops change that adds
the `pantry-mcp-credentials` ExternalSecret: ESO marks an ExternalSecret
whose Key Vault entry is missing as not Ready, and ArgoCD then reports the
pantry-infra Application Degraded until the entry exists.

## Teardown

```bash
terraform destroy
```

Deleting `pantry-root` cascades (the resources-finalizer) — ArgoCD prunes
every pantry resource it created, including the Postgres cluster and its PVC.
The platform layer is untouched.
