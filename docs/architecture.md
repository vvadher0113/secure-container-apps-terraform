# Architecture

This document records the address plan, security controls, and design decisions for the
`secure-container-apps-terraform` deployment.

---

## Address plan

| Subnet   | CIDR         | Delegation                         | NSG | Purpose |
|----------|--------------|-------------------------------------|-----|---------|
| snet-agw | 10.20.0.0/24 | none                                | yes | Application Gateway WAF v2 |
| snet-aca | 10.20.1.0/24 | `Microsoft.App/environments`        | yes | Container Apps environment (workload profiles) |
| snet-pe  | 10.20.2.0/24 | none                                | yes | Private endpoints for PostgreSQL, Key Vault, and ACR |

The VNet uses `10.20.0.0/22` so all three subnets fit inside a single parent CIDR.

### NSG rules

**snet-agw:** Allows inbound TCP 80 and 443 from `Internet` (required for App Gateway WAF v2
to receive client traffic), inbound TCP 65200-65535 from `GatewayManager` (required for
the App Gateway management plane), and all outbound to `VirtualNetwork`.

**snet-aca:** Allows outbound to `VirtualNetwork` on all ports and TCP 443 outbound to
`AzureCloud` for the Container Apps control plane. Denies all inbound from `Internet`.

**snet-pe:** Allows inbound from `VirtualNetwork` and denies everything else.

---

## Private DNS zones

Each PaaS resource has a private DNS zone linked to the VNet so that name resolution from
inside the VNet returns the private endpoint IP rather than the public IP.

| Zone | Service |
|------|---------|
| `privatelink.postgres.database.azure.com` | PostgreSQL Flexible Server |
| `privatelink.vaultcore.azure.net` | Key Vault |
| `privatelink.azurecr.io` | Azure Container Registry |

The Container Apps environment gets its own private DNS zone for its default domain
(for example `internal.azurecontainerapps.io`) with a wildcard A record pointing to the
environment's static IP. This lets App Gateway resolve the apps' FQDNs without leaving the
VNet.

---

## Identity model

All service-to-service authentication uses managed identities. There are no passwords, no
client secrets, and no long-lived tokens stored anywhere.

| Identity | Assigned to | Permissions |
|----------|-------------|-------------|
| `id-agw` | Application Gateway | Key Vault Secrets User (reads TLS certificate) |
| `id-web` | `web` container app | AcrPull on ACR, Key Vault Secrets User |
| `id-api` | `api` container app | AcrPull on ACR, Key Vault Secrets User, PostgreSQL Entra login |
| `id-migrate` | `migrate` container app job | AcrPull on ACR, PostgreSQL Entra administrator |

### PostgreSQL Entra authentication flow

1. `modules/postgresql-flexible` sets `password_auth_enabled = false` and registers
   `id-migrate` as the Entra administrator.
2. The `migrate` job runs `pgaadauth_create_principal_with_oid` to create a PostgreSQL
   role for `id-api` identified by its object ID (not its display name, which can change).
3. At runtime, the API calls `azure-identity`'s `ManagedIdentityCredential.get_token()` with
   the PostgreSQL audience `https://ossrdbms-aad.database.windows.net/.default` and passes the
   resulting token as the database password. `azure-identity` caches and refreshes the token
   internally: no external caching is required.

---

## Security controls

| Control | Implementation | Module or file |
|---------|----------------|----------------|
| No public data-plane on PostgreSQL | `public_network_access_enabled = false` | `modules/postgresql-flexible` |
| No public data-plane on Key Vault | `public_network_access_enabled = false` (default on module) | `modules/key-vault` |
| ACR default-deny network rules | `network_rule_set { default_action = "Deny" }` | `modules/container-registry` |
| ACR admin user disabled | `admin_enabled = false` | `modules/container-registry` |
| Container Apps environment internal only | `internal_load_balancer_enabled = true` | `modules/container-apps-environment` |
| WAF in Prevention mode | `policy_settings { mode = "Prevention" }` | `modules/app-gateway-waf` |
| OWASP managed rule set | `managed_rule_set { type = "Microsoft_DefaultRuleSet", version = "2.1" }` | `modules/app-gateway-waf` |
| TLS policy enforced | `ssl_policy { policy_name = "AppGwSslPolicy20220101S" }` | `modules/app-gateway-waf` |
| No password auth on PostgreSQL | `password_auth_enabled = false` | `modules/postgresql-flexible` |
| PostgreSQL connection logging | `log_connections = "on"` | `modules/postgresql-flexible` |
| PostgreSQL checkpoint logging | `log_checkpoints = "on"` | `modules/postgresql-flexible` |
| PostgreSQL connection throttling | `connection_throttle.enable = "on"` | `modules/postgresql-flexible` |
| Containers run non-root | `run_as_non_root = true`, UID 1001 | `app/api/Dockerfile`, `app/web/Dockerfile` |
| Key Vault RBAC mode | `rbac_authorization_enabled = true` | `modules/key-vault` |
| Key Vault purge protection | `purge_protection_enabled = true` | `modules/key-vault` |
| Managed identities, one per workload | User-assigned, separate for each app | `infra/envs/dev/main.tf` |
| State shared-key access disabled | `shared_access_key_enabled = false` | `bootstrap/main.tf` |
| State auth via Entra ID | `use_azuread_auth = true` | `infra/envs/dev/backend.tf` |
| HTTPS enforced on App Gateway | Certificate from Key Vault via `id-agw`; HTTP listener present for demo mode only | `modules/app-gateway-waf` |
| Private DNS zones for all PaaS | Zone linked to VNet, private endpoint DNS zone group | `modules/private-dns-zone`, `modules/private-endpoint` |
| CI image push uses JIT ACR IP rule | Runner IP added before push, removed in `if: always()` step | `.github/workflows/build-push.yml` |
| GitHub Actions uses OIDC, no secrets | `azure/login` with `ARM_USE_OIDC=true`; federated credential on the service principal | `.github/workflows/*.yml` |
| All GitHub Actions pinned to SHA | Every `uses:` line has a full commit SHA with version comment | `.github/workflows/*.yml` |

---

## Design decisions

### Container Apps over VMs or AKS

Container Apps removes cluster management overhead while still providing VNet integration and
workload profiles. It is the right fit when the workload is a small number of HTTP services
and jobs and the team does not need to manage node pools. AKS is the better choice when
workloads require custom admission controllers, DaemonSets, or specific node configurations.

The `internal_load_balancer_enabled = true` setting on the environment means the environment's
load balancer has no public IP. App Gateway is the only public entry point. Container apps
with `external_enabled = true` are reachable from the VNet (including App Gateway) but not
from the internet.

### Entra-only PostgreSQL

Eliminating password auth removes the entire class of credential-leakage incidents. The
trade-off is that local development requires either a local Postgres container or an
Entra-capable `psql` session (`psql "host=... password=$(az account get-access-token ...)")`).

Using `pgaadauth_create_principal_with_oid` instead of the name-based variant is deliberate:
object IDs are stable even when a service principal is renamed. The migrate job gets the OID
from the `azurerm_user_assigned_identity.api.principal_id` output, so Terraform manages the
binding end-to-end.

### Migration job runs in-network

The migration job needs the Entra admin role on PostgreSQL to create the API's database role.
Running it as a Container Apps Job inside the VNet means:
- It reaches Postgres through the private endpoint, never a public address.
- The Entra admin identity never reaches a public CI runner.
- The job is idempotent: re-running it is safe because `pgaadauth_create_principal_with_oid`
  is a no-op if the role already exists.

### ACR deny-by-default plus JIT CI access

Fully disabling the public endpoint on ACR Premium blocks `docker push` from CI runners.
The chosen design keeps the public endpoint but sets `default_action = "Deny"` with no
standing IP rules. The CI pipeline adds the runner's IP for the push window and removes it in
an `if: always()` step. The security posture in steady state is equivalent to a private-only
registry, without the operational complexity of self-hosted runners or private build agents.

### Two-phase image deploy

Container Apps requires a valid image reference when the resource is created. Because ACR is
private by default, Terraform cannot pull from it during the initial apply. The chosen pattern:

1. First `terraform apply` uses a public placeholder image to create infrastructure.
2. `build-push.yml` publishes real images to ACR using the JIT IP rule.
3. Second `terraform apply` updates the image references in state.

This keeps Terraform as the single source of truth for container configuration and avoids
side-channel image tag management.

### `/api` path prefix on the FastAPI router

App Gateway does path-based routing without stripping the prefix: a request for `/api/items`
arrives at the API as `/api/items`. Mounting the item routes under `APIRouter(prefix="/api")`
inside FastAPI makes the routes match without requiring App Gateway path rewrite rules. The
`/health` route stays at the root so App Gateway backend probes can hit it without the prefix.
Path rewrite rules are an alternative but add App Gateway configuration complexity for no
security benefit.

### Remote state design

State is stored in Azure Storage with Entra ID auth (`use_azuread_auth = true`) and shared
keys disabled. The state storage account is intentionally accessible from public IPs (no
network rules) because CI runners need to read and write state. Shared key access is disabled,
so only identities with explicit role assignments (Storage Blob Data Contributor) can access
state. A private endpoint on the state storage account is out of scope for this demo; in
production, add a private endpoint and use self-hosted runners or the `azure/login` action
with a service connection that routes through a private link.

---

## Observability

All PaaS resources ship logs to a central Log Analytics workspace:

| Resource | Diagnostic categories |
|----------|----------------------|
| App Gateway | `allLogs` |
| Container Apps environment | Configured by the managed service; forwarded to workspace |
| PostgreSQL | `allLogs` |
| Key Vault | `AuditEvent`, `allLogs` |
| ACR | `allLogs` |

The workspace is created by `modules/log-analytics` with a 30-day default retention.
