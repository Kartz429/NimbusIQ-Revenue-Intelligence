# NimbusIQ developer shortcuts. On Windows run these from Git Bash or WSL, or
# copy the underlying commands (they are all one-liners).
SHELL := /bin/bash
DBT   := cd nimbusiq && DBT_PROFILES_DIR=profiles dbt

.DEFAULT_GOAL := help

help:  ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'

install:  ## create .venv and install pinned dependencies
	python -m venv .venv
	. .venv/bin/activate && pip install -r requirements.txt && pip install -r requirements-dev.txt pytest

deps:  ## install dbt packages
	$(DBT) deps

debug:  ## verify the Snowflake connection
	$(DBT) debug

seed:  ## load reference data (FX rates)
	$(DBT) seed

build:  ## run + test every model, seed and snapshot in DAG order
	$(DBT) build

run:  ## build models only
	$(DBT) run

test:  ## run dbt data tests and unit tests
	$(DBT) test

snapshot:  ## capture SCD2 history
	$(DBT) snapshot

freshness:  ## check source freshness
	$(DBT) source freshness

docs:  ## generate and serve dbt docs
	$(DBT) docs generate && $(DBT) docs serve

lint:  ## ruff + sqlfluff + yamllint
	ruff check .
	sqlfluff lint nimbusiq/models nimbusiq/tests
	yamllint .

fmt:  ## auto-format python and fix SQL
	ruff check --fix . && ruff format .
	sqlfluff fix nimbusiq/models nimbusiq/tests

pytest:  ## python unit tests
	python -m pytest

data:  ## regenerate all CSV datasets (seeded)
	python scripts/generate_all.py

validate:  ## validate the CSV datasets
	python scripts/validate_datasets.py

docker-build:  ## build the dbt runner image
	docker build -t nimbusiq-dbt .

clean:  ## remove dbt build output
	$(DBT) clean

.PHONY: help install deps debug seed build run test snapshot freshness docs lint fmt pytest data validate docker-build clean
