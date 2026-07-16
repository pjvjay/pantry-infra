# ============================================================
# The pantry database password.
#
# Flow: random_password (state-only) → Key Vault entry →
# External Secrets Operator projects it into the pantry-db and
# pantry-app namespaces (manifests in pantry-gitops) → CNPG bootstrap
# + API pods consume the projected Secrets.
#
# Single source of truth is Key Vault; nothing in git, nothing typed
# by a human.
# ============================================================

resource "random_password" "pantry_db" {
  length = 24
  # Alphanumeric only: the password rides inside a Postgres connection
  # URL and psql env vars — dodging URL-encoding edge cases entirely
  # beats handling them. 24 alphanumeric chars ≈ 143 bits of entropy.
  special = false
}

resource "azurerm_key_vault_secret" "pantry_db_password" {
  name         = "pantry-db-password"
  value        = random_password.pantry_db.result
  key_vault_id = data.azurerm_key_vault.kv.id

  content_type = "pantry-platform demo — Postgres pantry_app role password"

  tags = {
    project   = "pantry-platform"
    managedBy = "terraform"
  }
}
