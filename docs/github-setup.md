# GitHub setup

## 1. Push the code

```bash
git remote add origin https://github.com/<you>/<repo>.git   # skip if it already exists
git push -u origin main
```

If the GitHub repository already has history, do **not** force-push. Add this version
as a branch and review it through a pull request:

```bash
git remote add origin https://github.com/<you>/<repo>.git
git fetch origin
git push origin main:production-ready     # then open a PR: production-ready -> main
```

(The first `git push` is rejected if histories are unrelated; the PR route avoids overwriting
anything. GitHub will show the full diff, and `docs/migration-notes.md` lists what changed.)

## 2. Secrets (Settings -> Secrets and variables -> Actions -> Secrets)

| Secret | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | e.g. `xy12345.eu-west-1` |
| `SNOWFLAKE_USER` | `DBT_USER` |
| `SNOWFLAKE_PRIVATE_KEY` | full PEM text of the dbt user's private key |
| `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` | only if the key is encrypted |

Variables (same page, *Variables* tab): `ENABLE_SNOWFLAKE_CI=true` once the secrets
exist; optional `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`.

## 3. Environment

Settings -> Environments -> **New environment: `production`**. Add required reviewers if
you want a manual approval before scheduled/manual deploys.

## 4. Branch protection (Settings -> Branches -> `main`)

* Require a pull request before merging
* Require status checks: `Lint`, `Python tests and dataset validation`, `dbt deps + parse`
  (add `dbt build on Snowflake` once `ENABLE_SNOWFLAKE_CI` is on)
* Require branches to be up to date; block force pushes

## 5. Optional

* Enable *Secret scanning* and *Push protection* (Settings -> Code security).
* Install hooks locally: `pip install -r requirements-dev.txt && pre-commit install`.

## 6. Git LFS

The six CSVs total ~57 MB (largest 24 MB), below GitHub's 100 MB per-file limit, so plain
Git is fine. If you scale the data up, move `datasets/*.csv` to Git LFS or object storage.
