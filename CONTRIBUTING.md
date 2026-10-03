# Contributing

1. Branch from `main`: `git checkout -b feature/<short-name>`.
2. `pip install -r requirements.txt -r requirements-dev.txt pytest && pre-commit install`.
3. Develop against the `dev` target (writes only to your `DBT_SCHEMA_*` schemas).
4. Add or update tests and the model's `.yml` description for every change.
5. `make lint && make pytest && make build` before opening a PR.
6. Open a PR; CI must be green. Call out breaking changes in the PR template.

Commit style: short imperative subject (`Add currency conversion`), body explains *why*.
