[< Back to Navigation](../README.md)

# Managing Environment Variables in Azure KeyVault

This guide explains how to add and manage environment variables using Azure KeyVault for the Teacher Training Entitlement application.

## Overview

Azure KeyVault is used to securely store environment variables and secrets for the application. There are two types of KeyVaults per environment:

- **Application KeyVault** (`app-kv`) - for application-related environment variables
- **Infrastructure KeyVault** (`inf-kv`) - for infrastructure-related configuration

## Accessing Azure KeyVault

1. Navigate to the [Azure Portal KeyVault browser](https://portal.azure.com/#browse/Microsoft.KeyVault%2Fvaults)

2. Login using your `@digitalauth.education.gov.uk` account

   > Make sure "DfE Platform Identity" appears in the top right corner below your name. If not, click the settings/cog icon and select it from the list of directories.

3. Search for `cpdtte` in the search box to filter the KeyVaults

## KeyVault Naming Convention

All KeyVaults follow this naming pattern:

```
s189p01-cpdtte-<env>-<type>-kv
```

Where:
- `<env>` is the environment code (see table below)
- `<type>` is either `app` or `inf`

### Available Environments

| Environment Code | Environment Name | KeyVault Examples |
|-----------------|------------------|-------------------|
| `pd` | Production | `s189p01-cpdtte-pd-app-kv`<br>`s189p01-cpdtte-pd-inf-kv` |
| `st` | Staging | `s189p01-cpdtte-st-app-kv`<br>`s189p01-cpdtte-st-inf-kv` |
| `sb` | Sandbox | `s189p01-cpdtte-sb-app-kv`<br>`s189p01-cpdtte-sb-inf-kv` |
| `rv` | Review | `s189p01-cpdtte-rv-app-kv`<br>`s189p01-cpdtte-rv-inf-kv` |

## Choosing the Right KeyVault

### Application KeyVault (`app-kv`)

Use this for application-specific environment variables such as:
- API keys for external services
- Application feature flags
- Third-party service credentials
- Application-specific secrets

### Infrastructure KeyVault (`inf-kv`)

Use this for infrastructure-related configuration such as:
- Azure resource credentials
- Container registry credentials
- Monitoring and logging service keys
- Infrastructure automation secrets
- Network configuration credentials

## Adding Environment Variables

1. Select the appropriate KeyVault based on:
   - The environment (production, staging, sandbox, review)
   - The type (application or infrastructure)

2. Navigate to the **Secrets** section in the KeyVault

3. Click **Generate/Import** to add a new secret

4. Fill in the required fields:
   - **Name**: The environment variable name (e.g., `DATABASE_URL`, `API_KEY`)
   - **Value**: The secret value
   - **Content type** (optional): Description of what the secret is for
   - **Activation/Expiration dates** (optional): Set if the secret has time restrictions

5. Click **Create** to save the secret

## Production Access

> **Important**: Accessing the production KeyVaults requires elevated privileges through a PIM (Privileged Identity Management) request.

To access production KeyVaults:

1. Visit the [PIM Activation page](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup)
2. Activate the 'Member' role for the `s189 CPD production PIM` group
3. Provide a reason for your request and submit
4. Wait for approval from another team member

You can view and approve pending requests [here](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/~/aadgroup).

## Best Practices

- Use descriptive names for secrets (e.g., `SENDGRID_API_KEY` rather than `KEY1`)
- Add a content type description to help other team members understand the secret's purpose
- Never commit secrets to source control - always use KeyVault
- When rotating secrets, update them in KeyVault rather than creating duplicates
- Document any new environment variables in the application's `.env.template` file (with placeholder values)
- Test new environment variables in lower environments (review/sandbox) before adding to production

## Related Documentation

- [Connecting to Azure](connecting-to-azure.md)
- [Environments](environments.md)
