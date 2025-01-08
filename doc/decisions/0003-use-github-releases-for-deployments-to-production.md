# 3. Use GitHub Releases for deployments to production

Date: 14 November 2023

Status: Accepted

## Context

The existing production deployment process for PSD involves two branches - `develop` and `main`. `develop` is the working branch and target for all feature branches. A GitHub workflow deploys `develop` to staging for each merge.

When a production deployment is required, `develop` is merged into `main`, which triggers another GitHub workflow to deploy to pre-prod and production.

Due to hotfixes merged directly into `main` as well as non-rebase merges when merging `develop` into `main` and mismatching commit hashes when merging hotfixes back into `develop`, the `develop` to `main` merge nearly always encounters conflicts in both directions, thereby preventing a production deployment from happening via the agreed PR process.

In these situations, the workaround involves deleting `main` then pushing a copy of `develop` as `main` to trigger the GitHub workflow with the latest code. This is dangerous since it involves deleting the `main` branch as well as temporarily disabling branch protection.

This process also makes it difficult to deploy anything other than the current state of the `develop` branch or to roll back if required.

## Decision

PSD will transition to a deployment workflow based on GitHub Releases. There will be one branch (`main`) which will be the working branch and target for all feature branches. Merges to `main` will trigger a GitHub workflow to deploy to staging in a similar manner to the existing workflow.

When a production deployment is required, a new GitHub Release will be created with a tag based on a version number (e.g. `v1.0.10`). The creation of this release will trigger a GitHub workflow to deploy to pre-prod and production.

Pros
----
* Prevents merge conflicts during the `develop` to `main` merge process
* Allows a release to be created based on an existing tag that represents a point in `main` other than the current state
* Allows a deployment to be triggered based on an older tag to roll back

Cons
----
* Requires creation of a GitHub Release which is a new process compared to the known PR process

## Alternatives

A full git flow process was considered which would involve creating release branches based off a two-branch (`develop` and `main`) layout. However, this would still require the release branch to be merged into `main` as well as back into `develop`, therefore it would double the amount of work per deployment and not necessarily prevent merge conflicts. Full git flow is also difficult to implement fully in GitHub especially with branch protection and is too heavy for our requirements.

## Consequences

There are no significant consequences.
