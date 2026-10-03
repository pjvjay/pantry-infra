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

# ============================================================
# The pantry MCP bearer token.
#
# pantry-api serves its MCP endpoint (/mcp) over HTTP and reads
# MCP_AUTH_TOKENS: a comma-separated list of `label:secret` entries.
# A client presents `Authorization: Bearer <secret>`; the server
# looks the secret up and records the matching LABEL as the
# submitter/reviewer on origin submissions, so the label is the audit
# identity, never the secret. Without any token configured the API
# runs /mcp anonymously with submissions disabled.
#
# Same flow as the DB password: random_password (state-only) →
# Key Vault entry → ExternalSecret `pantry-mcp-credentials` in
# pantry-app (manifest in pantry-gitops) → API Deployment env.
# ============================================================

resource "random_password" "pantry_mcp_token" {
  length = 32
  # Alphanumeric only: the secret rides in an HTTP header and a shell
  # pipeline (`cut -d: -f2`), so no colons, quotes or shell metachars.
  # 32 alphanumeric chars ≈ 190 bits of entropy.
  special = false
}

resource "azurerm_key_vault_secret" "pantry_mcp_tokens" {
  name         = "pantry-mcp-tokens"
  value        = "terraform:${random_password.pantry_mcp_token.result}"
  key_vault_id = data.azurerm_key_vault.kv.id

  content_type = "pantry-platform demo — MCP bearer tokens (label:secret[,label:secret])"

  tags = {
    project   = "pantry-platform"
    managedBy = "terraform"
  }
}
