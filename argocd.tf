# ============================================================
# The GitOps seed — ArgoCD root Application.
#
# This is the ONLY Kubernetes object Terraform creates. It points
# ArgoCD at pantry-gitops/argocd/, which contains the AppProject and
# the child Applications; ArgoCD recursively creates everything else.
#
# Mirror manifest: pantry-gitops/argocd/root-app.yaml (the kubectl
# fallback for clusters without this Terraform).
# ============================================================

resource "kubernetes_manifest" "pantry_root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "pantry-root"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io",
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = "argocd"
        directory = {
          recurse = false
          exclude = "root-app.yaml"
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }

  # Make sure the DB password exists in Key Vault before ArgoCD starts
  # syncing manifests whose ExternalSecrets reference it.
  depends_on = [azurerm_key_vault_secret.pantry_db_password]
}
