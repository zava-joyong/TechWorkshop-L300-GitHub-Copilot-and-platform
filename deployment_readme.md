# ZavaStorefront Deployment

## GitHub Actions CI/CD Setup

### Required Secrets

Create the following secret in your repository (**Settings → Secrets and variables → Actions → Secrets**):

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal credentials (JSON format) |

Generate `AZURE_CREDENTIALS` by running:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --sdk-auth
```

Copy the entire JSON output as the secret value.

### Required Variables

Create the following variables (**Settings → Secrets and variables → Actions → Variables**):

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_WEBAPP_NAME` | Name of your App Service | `azappxxxxxxxxx` |
| `ACR_LOGIN_SERVER` | ACR login server URL | `azacrxxxxxxxxx.azurecr.io` |

Get these values after running `azd up`:

```bash
azd env get-values | grep -E "WEB_APP_NAME|ACR_LOGIN_SERVER"
```

### Trigger Deployment

- **Automatic**: Push to `main` branch
- **Manual**: Go to **Actions → Deploy to Azure → Run workflow**
