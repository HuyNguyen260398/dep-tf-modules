# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository contains custom reusable Terraform modules for AWS services. Modules follow a consistent structure and are designed for composition across environments.

## Repository Structure

```
modules/
└── aws/
    └── <service>/          # One directory per AWS service
        ├── main.tf         # Resource definitions
        ├── variables.tf    # Input variables with validation
        ├── outputs.tf      # Exported attributes
        ├── versions.tf     # Provider and Terraform version constraints
        ├── README.md       # Module documentation
        ├── examples/
        │   └── complete/   # Runnable usage example
        └── tests/
            └── *_test.go   # Terratest integration tests
```

## Terraform Commands

```bash
# Initialize a module or example
terraform init

# Validate configuration
terraform validate

# Format all .tf files
terraform fmt -recursive

# Plan (from an examples/ directory)
terraform plan

# Run all tests for a module
cd modules/aws/<service>/tests
go test -v -timeout 30m

# Run a single test
go test -v -run TestMyModule -timeout 30m
```

## Module Authoring Standards

- **variables.tf**: Every variable must have `description`. Add `validation` blocks for string formats (CIDR, ARN patterns, allowed values).
- **outputs.tf**: Export the primary resource ID, ARN, and any attributes needed for module composition.
- **versions.tf**: Pin minimum Terraform version and AWS provider version using `~>` constraints.
- **Tags**: All taggable resources must accept a `tags = map(string)` variable and `merge()` it with a `Name` tag local.
- **Conditional resources**: Use `count = var.create_x ? 1 : 0` pattern for optional sub-resources.
- **Locals**: Use `locals {}` for computed/repeated values instead of inline expressions.

## Skills Available

| Skill | Invoke with |
|-------|-------------|
| Scaffold a new AWS module | `/terraform-module-library` |
| Generate README for a module | `/create-readme` |
| GitHub CLI operations | `/gh-cli` |
