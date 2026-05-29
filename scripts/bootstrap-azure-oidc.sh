#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/bootstrap-azure-oidc.sh \
    --subscription-id <azure-subscription-id> \
    --github-owner <github-user-or-org> \
    --github-repo <repo-name> \
    [--location australiaeast]

Creates:
  - Azure AD app registration/service principal for GitHub OIDC
  - Federated credentials for refs/heads/main and pull request plans
  - Terraform state resource group, storage account, and container
  - Contributor role assignment at subscription scope
  - Storage Blob Data Contributor role assignment for Terraform state

Requires:
  az login
EOF
}

SUBSCRIPTION_ID=""
GITHUB_OWNER=""
GITHUB_REPO=""
LOCATION="australiaeast"
PROJECT="familyalbum"
ENVIRONMENT="prod"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription-id)
      SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    --github-owner)
      GITHUB_OWNER="$2"
      shift 2
      ;;
    --github-repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SUBSCRIPTION_ID" || -z "$GITHUB_OWNER" || -z "$GITHUB_REPO" ]]; then
  usage
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required. Install it or run this script in Azure Cloud Shell." >&2
  exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID"

TENANT_ID="$(az account show --query tenantId -o tsv)"
APP_NAME="${PROJECT}-${ENVIRONMENT}-github-oidc"
STATE_RG="rg-${PROJECT}-tfstate"
STATE_CONTAINER="tfstate"
STATE_KEY="${PROJECT}-${ENVIRONMENT}.tfstate"
SUBSCRIPTION_COMPACT="${SUBSCRIPTION_ID//-/}"
STATE_STORAGE="sttf${PROJECT}${SUBSCRIPTION_COMPACT}"
STATE_STORAGE="${STATE_STORAGE:0:24}"

echo "Creating GitHub OIDC application: ${APP_NAME}"
APP_ID="$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv)"

if [[ -z "$APP_ID" ]]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
else
  echo "Reusing existing application: ${APP_ID}"
fi

SP_OBJECT_ID="$(az ad sp list --filter "appId eq '${APP_ID}'" --query '[0].id' -o tsv)"

if [[ -z "$SP_OBJECT_ID" ]]; then
  SP_OBJECT_ID="$(az ad sp create --id "$APP_ID" --query id -o tsv)"
else
  echo "Reusing existing service principal: ${SP_OBJECT_ID}"
fi

echo "Adding federated credentials for ${GITHUB_OWNER}/${GITHUB_REPO}"
if [[ "$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='github-main'] | length(@)" -o tsv)" == "0" ]]; then
  cat > /tmp/familyalbum-federated-credential.json <<EOF
{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main",
  "description": "GitHub Actions main branch",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

  az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters /tmp/familyalbum-federated-credential.json >/dev/null
else
  echo "Reusing existing github-main federated credential"
fi

if [[ "$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='github-pull-request'] | length(@)" -o tsv)" == "0" ]]; then
  cat > /tmp/familyalbum-federated-credential.json <<EOF
{
  "name": "github-pull-request",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:pull_request",
  "description": "GitHub Actions pull request plans",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

  az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters /tmp/familyalbum-federated-credential.json >/dev/null
else
  echo "Reusing existing github-pull-request federated credential"
fi

rm -f /tmp/familyalbum-federated-credential.json

echo "Assigning Contributor role at subscription scope"
SUBSCRIPTION_SCOPE="/subscriptions/${SUBSCRIPTION_ID}"
if [[ "$(az role assignment list --assignee "$APP_ID" --scope "$SUBSCRIPTION_SCOPE" --query "[?roleDefinitionName=='Contributor'] | length(@)" -o tsv)" == "0" ]]; then
  az role assignment create \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role Contributor \
    --scope "$SUBSCRIPTION_SCOPE" >/dev/null
else
  echo "Reusing existing Contributor role assignment"
fi

echo "Creating Terraform state storage"
az group create \
  --name "$STATE_RG" \
  --location "$LOCATION" >/dev/null

if ! az storage account show --name "$STATE_STORAGE" --resource-group "$STATE_RG" >/dev/null 2>&1; then
  az storage account create \
    --name "$STATE_STORAGE" \
    --resource-group "$STATE_RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false >/dev/null
else
  echo "Reusing existing Terraform state storage account: ${STATE_STORAGE}"
fi

STATE_STORAGE_ID="$(az storage account show \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --query id \
  -o tsv)"

echo "Assigning Terraform state blob access"
if [[ "$(az role assignment list --assignee "$APP_ID" --scope "$STATE_STORAGE_ID" --query "[?roleDefinitionName=='Storage Blob Data Contributor'] | length(@)" -o tsv)" == "0" ]]; then
  az role assignment create \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Contributor" \
    --scope "$STATE_STORAGE_ID" >/dev/null
else
  echo "Reusing existing Terraform state blob role assignment"
fi

STATE_ACCOUNT_KEY="$(az storage account keys list \
  --account-name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --query '[0].value' \
  -o tsv)"

az storage container create \
  --name "$STATE_CONTAINER" \
  --account-name "$STATE_STORAGE" \
  --account-key "$STATE_ACCOUNT_KEY" >/dev/null

cat <<EOF

Bootstrap complete.

Add these GitHub repository secrets:

ARM_CLIENT_ID=${APP_ID}
ARM_TENANT_ID=${TENANT_ID}
ARM_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
TF_STATE_RESOURCE_GROUP_NAME=${STATE_RG}
TF_STATE_STORAGE_ACCOUNT_NAME=${STATE_STORAGE}
TF_STATE_CONTAINER_NAME=${STATE_CONTAINER}
TF_STATE_KEY=${STATE_KEY}

Also add these GitHub repository secrets from your app config:

TF_VAR_GOOGLE_CLIENT_ID=<your-google-client-id>
TF_VAR_GOOGLE_CLIENT_SECRET=<your-google-client-secret>
TF_VAR_NEXTAUTH_SECRET=<your-nextauth-secret>
TF_VAR_ALLOWED_EMAILS_JSON=["person1@gmail.com","person2@gmail.com"]

EOF
