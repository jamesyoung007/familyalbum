# Family Album

A private family photo album built with Next.js, Google sign-in, an email allowlist, and Azure Blob Storage.

## What This App Does

- Lets family members sign in with Google.
- Allows access only when their email is listed in `ALLOWED_EMAILS`.
- Uploads photos to a private Azure Blob Storage container.
- Shows signed, short-lived image URLs only to authenticated family members.
- Deploys to Azure App Service from GitHub Actions.

## Step 1: Install And Run Locally

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:3000`.

## Step 2: Create Google OAuth Credentials

1. Go to Google Cloud Console.
2. Create or choose a project.
3. Configure the OAuth consent screen.
4. Create an OAuth Client ID for a web application.
5. Add this authorized redirect URI for local development:

```text
http://localhost:3000/api/auth/callback/google
```

6. Put the client ID and secret into `.env.local`.

## Step 3: Bootstrap Azure For GitHub Actions

The Azure resources are managed by Terraform in `infra/`.

You still need one Azure identity that GitHub Actions can use. The bootstrap script creates that identity, configures GitHub OIDC, and creates the Terraform remote state storage.

First, create an empty GitHub repository, but do not push yet. Then run this from your machine or Azure Cloud Shell:

```bash
az login

scripts/bootstrap-azure-oidc.sh \
  --subscription-id <your-azure-subscription-id> \
  --github-owner <your-github-username-or-org> \
  --github-repo <your-github-repo-name>
```

The script prints the GitHub secrets you need to add.

## Step 4: Configure GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

Add the Azure and Terraform state secrets printed by the bootstrap script:

```text
ARM_CLIENT_ID
ARM_TENANT_ID
ARM_SUBSCRIPTION_ID
TF_STATE_RESOURCE_GROUP_NAME
TF_STATE_STORAGE_ACCOUNT_NAME
TF_STATE_CONTAINER_NAME
TF_STATE_KEY
```

Add these app secrets:

```text
TF_VAR_GOOGLE_CLIENT_ID
TF_VAR_GOOGLE_CLIENT_SECRET
TF_VAR_NEXTAUTH_SECRET
TF_VAR_ALLOWED_EMAILS_JSON
```

`TF_VAR_ALLOWED_EMAILS_JSON` must be a JSON list:

```json
["person1@gmail.com", "person2@gmail.com"]
```

For `TF_VAR_NEXTAUTH_SECRET`, use a long random value. Locally, you can generate one with:

```bash
openssl rand -base64 32
```

## Step 5: Deploy Azure Infrastructure And App

After the secrets are configured, push to the `main` branch. The `.github/workflows/azure.yml` workflow will:

1. Run `terraform fmt`, `terraform init`, `terraform validate`, and `terraform plan`.
2. Apply Terraform on `main` and `workflow_dispatch`.
3. Create Azure resources:
   - Resource group
   - Private Azure Blob Storage account and container
   - Linux App Service Plan
   - Linux Web App
   - Web app application settings
4. Build the Next.js app.
5. Deploy the standalone Next.js artifact to Azure App Service.

After the first successful run, check the workflow summary for the Google OAuth redirect URI. It will look like:

```text
https://app-familyalbum-prod-xxxxxx.azurewebsites.net/api/auth/callback/google
```

Add that URI to your Google OAuth client.

## Optional: Cloudflare Custom Domain

The Terraform workflow can manage a Cloudflare DNS hostname and bind it to Azure App Service with an Azure-managed TLS certificate.

Use a Cloudflare **API token**, not the global API key. Give it the least privilege needed for one zone:

```text
Zone:Read
DNS:Edit
```

Then add these GitHub repository secrets:

```text
CLOUDFLARE_API_TOKEN
TF_VAR_CLOUDFLARE_ZONE_ID
```

Add these GitHub repository variables, not secrets:

```text
TF_VAR_CUSTOM_DOMAIN_ENABLED=true
TF_VAR_CUSTOM_DOMAIN_HOSTNAME=album.yourdomain.com
```

The hostname is not sensitive. Keeping it as a repository variable lets GitHub Actions pass the generated Google OAuth redirect URI between jobs and print it in the deployment summary.

Keep the Cloudflare record DNS-only at first. Terraform sets `proxied = false` so Azure can validate the hostname and issue the managed certificate. After the first successful deployment and certificate binding, you can decide whether to proxy it through Cloudflare.

After the custom domain workflow succeeds, add the new Google OAuth redirect URI:

```text
https://album.yourdomain.com/api/auth/callback/google
```

## Step 6: Local Development

For local development only, `.env.local` still needs local values:

```env
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
ALLOWED_EMAILS=person1@gmail.com,person2@gmail.com
AZURE_STORAGE_CONNECTION_STRING=...
AZURE_STORAGE_CONTAINER=family-photos
```

If you do not want to create local Azure storage credentials, test the deployed app instead.

Anyone outside `ALLOWED_EMAILS` or `TF_VAR_ALLOWED_EMAILS_JSON` will be rejected during sign-in.

## Optional Terraform Commands

You do not need Terraform installed locally. GitHub Actions installs and runs Terraform for normal deployments.

These commands are only for future debugging if you ever choose to install Terraform:

```bash
cd infra
terraform fmt -recursive
terraform init -backend-config=backend.hcl
terraform validate
terraform plan
```

Copy `infra/backend.hcl.example` to `infra/backend.hcl` if you need to run Terraform locally.

## Useful Commands

```bash
npm run dev
npm run build
npm start
```

## Notes

- The storage container is private.
- The app emits short-lived signed image URLs only after authentication.
- App Service runs Node 22 and starts the standalone Next.js server with `node server.js`.
- The default App Service Plan SKU is `B1`. Change `app_service_sku_name` if you want a cheaper or larger tier.

## References

- Azure App Service GitHub Actions: https://learn.microsoft.com/en-us/azure/app-service/deploy-github-actions
- Azure Storage connection strings: https://learn.microsoft.com/en-us/azure/storage/common/storage-configure-connection-string
- Google OAuth clients: https://support.google.com/cloud/answer/6158849
