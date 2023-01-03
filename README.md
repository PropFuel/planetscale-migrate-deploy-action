# PlanetScale Migrate and Deploy Action

This action will create a new branch in your PlanetScale database, open a connection to the branch, run your migrations, create a deploy request, and deploy the deploy request to your main branch.

## Usage

Add the following entry to your Github workflow YAML file with the following required inputs:

```yaml
uses: PropFuel/planetscale-deploy-action@v1.0.0
with:
  planetscale-service-token-id: ${{ secrets.PLANETSCALE_SERVICE_TOKEN_ID }}
  planetscale-service-token: ${{ secrets.PLANETSCALE_SERVICE_TOKEN }}
  planetscale-org-name: ${{ secrets.PLANETSCALE_ORG_NAME }}
  planetscale-db-name: ${{ secrets.PLANETSCALE_DB_NAME }}
  migrate-command: command to run for migration
```

### Service Tokens

PlanetScale service tokens can be generated in the PlanetScale [settings page](https://app.planetscale.com/propfuel/settings/service-tokens).

The generated service token should have, at the very least, the following access permissions set:

- `create_branch`
- `read_branch`
- `delete_branch`
- `connect_branch`
- `create_deploy_reqest`
- `read_deploy_request`

### Required Inputs

We recommend storing sensitive data as [GitHub encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

| Input                          | Description                                  |
| ------------------------------ | -------------------------------------------- |
| `planetscale-service-token-id` | Your PlanetScale service token ID.           |
| `planetscale-service-token`    | Your PlanetScale service token value.        |
| `planetscale-org-name`         | Your PlanetScale organization name.          |
| `planetscale-db-name`          | Your PlanetScale database name.              |
| `migrate-command`              | The command to run your database migrations. |

### Optional Inputs

| Input         | Description                                 | Default                                   |
| ------------- | ------------------------------------------- | ----------------------------------------- |
| `branch-name` | The branch name to use for this deployment. | Current timestamp (e.g. `20221105063014`) |

## Examples

Migrate and deploy a Laravel application when there's a change in the `database/migrations` directory:

```yaml
name: PlanetScale Migrate and Deploy

on:
  push:
    branches:
      - main
    paths:
      - database/migrations

jobs:
  migrate-deploy:
    name: Migrate and deploy
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Deploy
        uses: PropFuel/planetscale-deploy-action@v1.0.0
        env:
          # These are Laravel-specific variables needed for the migrations to run
          DB_HOST: 127.0.0.1
          DB_DATABASE: ${{ env.PLANETSCALE_DB_NAME }}
          DB_USERNAME:
          DB_PASSWORD:
        with:
          planetscale-service-token-id: ${{ secrets.PLANETSCALE_SERVICE_TOKEN_ID }}
          planetscale-service-token: ${{ secrets.PLANETSCALE_SERVICE_TOKEN }}
          planetscale-org-name: ${{ secrets.PLANETSCALE_ORG_NAME }}
          planetscale-db-name: ${{ secrets.PLANETSCALE_DB_NAME }}
          branch-name: my-first-automated-branch
          migrate-command: php artisan migrate --force
```
