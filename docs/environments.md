[< Back to Navigation](../README.md)

# Environments

There are three permanent environments for TTE (Teacher Training Entitlement), plus a review app for the life of each Pull Request:

| Environment | URL                                                                                 | Used by                              | Purpose                                               | Deployment trigger                        | Azure space | Deployed commit                                                                                  |
|-------------|-------------------------------------------------------------------------------------|--------------------------------------|-------------------------------------------------------|-------------------------------------------|-------------|--------------------------------------------------------------------------------------------------|
| Production  | https://teacher-training-entitlement.education.gov.uk                               | Real users                           | Live system                                           | Merge to `main`                           | production  | [View](https://teacher-training-entitlement.education.gov.uk/healthcheck.json)                   |
| Sandbox     | https://sandbox.teacher-training-entitlement.education.gov.uk                       | External users (e.g. lead providers) | Explore the service without affecting production data | Merge to `main`                           | production  | [View](https://sandbox.teacher-training-entitlement.education.gov.uk/healthcheck.json)      |
| Staging     | https://staging.teacher-training-entitlement.education.gov.uk                       | Team members                         | Production-like environment without real data         | Merge to `main`                           | test        | [View](https://staging.teacher-training-entitlement.education.gov.uk/healthcheck.json) |
| Review      | https://teacher-training-entitlement-review-_PR-NUMBER_.test.teacherservices.cloud/ | Team members                         | Review changes prior to merging                       | Open a PR (auto-destroyed on merge/close) | test        | Per-app                                                                                          |

Security in the `production` Azure space is configured for sensitive data. You need to log in with real admin credentials in these environments, and you'll need an Azure PIM to run `make` commands against them.

The `test` space should contain only seed/test data. Use dummy admin logins in these environments, and you won't need a PIM for `make`.
