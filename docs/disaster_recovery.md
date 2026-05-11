# Disaster Recovery

## Data Recovery

This is a summary of steps from this [documentation](https://github.com/DFE-Digital/teacher-services-cloud/blob/main/documentation/disaster-recovery.md)

This section describes how to restore the production or sandbox database from a backup. Follow each step in order.

> ⚠️ **Before you begin:** Ensure you have the appropriate Azure and GitHub permissions for the target environment.

---

### Step 1 — Prevent merges to main

Block merges to `main` to prevent any workflows triggering during the restore process.

1. Open the [Rulesets → main-branch](https://github.com/DFE-Digital/teacher-training-entitlement/settings/rules/10350356) settings page.
2. Under **Require a pull request before merging**, set **Required approvals** to `6`.

---

### Step 2 — Enable maintenance mode

Put the service into maintenance mode to prevent users from accessing it while the restore is in progress.

Run the [GitHub Actions → Set Maintenance Mode](https://github.com/DFE-Digital/teacher-training-entitlement/actions/workflows/maintenance.yml) workflow. This serves a [static maintenance page](/maintenance_page/html/index.html) to all users.

---

### Step 3 — Locate the backup file

Daily backups are taken automatically for both Production and Sandbox environments. Backup files are stored in Azure Blob Storage at the following path:

**Azure Portal → Storage accounts → `<container-name>` → Containers → `database-backup`**

Container names follow this convention: `<subscription><servicecodename><db><bkp><environment>sa`

| Environment | Container name           | Portal link |
|-------------|--------------------------|-------------|
| Production  | `s189p01cpdttedbbkppdsa` | [Open in Azure Portal](https://portal.azure.com/#view/Microsoft_Azure_Storage/ContainerMenuBlade/~/overview/storageAccountId/%2Fsubscriptions%2F3c033a0c-7a1c-4653-93cb-0f2a9f57a391%2FresourceGroups%2Fs189p01-cpdtte-pd-rg%2Fproviders%2FMicrosoft.Storage%2FstorageAccounts%2Fs189p01cpdttedbbkppdsa/path/database-backup/etag/%220x8DE5FF2B3747E23%22/defaultId//publicAccessVal/None) |
| Sandbox     | `s189p01cpdttedbbkpsbsa` | [Open in Azure Portal](https://portal.azure.com/#@platform.education.gov.uk/resource/subscriptions/3c033a0c-7a1c-4653-93cb-0f2a9f57a391/resourceGroups/s189p01-cpdtte-sb-rg/providers/Microsoft.Storage/storageAccounts/s189p01cpdttedbbkpsbsa/storagebrowser) |

Note the **exact filename** of the backup you intend to restore — you will need it in the next step.

---

### Step 4 — Restore the database

Run the [GitHub Actions → Restore Database](https://github.com/DFE-Digital/teacher-training-entitlement/actions/workflows/restore_azure_database.yml) workflow. When prompted, enter the backup filename identified in [Step 3](#step-3--locate-the-backup-file).

---

### Step 5 — Re-enable merges to main

Once the restore is complete and the service is verified as healthy, reverse the branch protection change made in Step 1.

1. Open the [Rulesets → main-branch](https://github.com/DFE-Digital/teacher-training-entitlement/settings/rules/10350356) settings page.
2. Under **Require a pull request before merging**, reset **Required approvals** to its original value.

Disable maintenance mode by re-running the [GitHub Actions → Set Maintenance Mode](https://github.com/DFE-Digital/teacher-training-entitlement/actions/workflows/maintenance.yml) workflow and toggling it off.
