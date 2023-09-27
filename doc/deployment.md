## Deployment

Create your changes in a new branch and open a pull request.

Pull requests trigger a deployment to the `int` space on GOV.UK PaaS of a temporary review application, which is then deleted when the PR is merged. The review application can be viewed at https://psd-pr-XXXX.london.cloudapps.digital/ (where XXXX is the PR number).

Merging requires passing tests, code style checks and at least one approving review.

The `develop` branch represents the staging environment and `main` the pre-prod and production environments. Anything merged into `develop` will trigger a deployment to staging, and anything merged into `main` will trigger a deployment to pre-prod and production.

### Review applications

In order to make the PR review process fast and independent, it is possible to create a short-lived environment for a given change. In order to create your environment, run `APP_NAME=ticket-123 ./deploy-review.sh`, where `ticket-123` is desired name of review app.

By default, the database is shared, but this can be overridden by setting the `DB_NAME` environment variable. This will create a new database instance, however this can take several minutes.

#### Custom environment variables in review application

Variables used by `deploy-review.sh` can be overridden. To do so, create a `.github/workflows/overrides/branch-name.env` file, where `branch-name` is the name of the branch used for the PR. Define variables in this file:

```
export DB_NAME=psd-db-custom-db
```

To export the variables, use the `source` command.

#### Debugging review application

Please run debug app deployment locally. See [".github/workflows/review-apps.yml"](https://github.com/UKGovernmentBEIS/beis-opss-psd/blob/master/.github/workflows/review-apps.yml) for details.

### Deployment from scratch

Once you have a GOV.UK PaaS account as mentioned above, you should install the Cloud Foundry CLI v7 beta (`cf`) from https://docs.cloudfoundry.org/cf-cli/v7.html and then run the following commands:

    cf login
    cf target -o beis-opss

This will log you in and set the correct target organisation.

If you need to create a new environment, you can run `cf create-space SPACE-NAME`, otherwise, select the correct space using `cf target -o beis-opss -s SPACE-NAME`.

#### Database

To create a database for the current space:

    cf marketplace -e postgres
    cf enable-service-access postgres
    cf create-service postgres small-ha-11 psd-database -c '{"enable_extensions": ["pgcrypto"]}'

#### Opensearch

To create an Opensearch instance for the current space:

    cf marketplace -s opensearch
    cf create-service opensearch tiny-1 psd-opensearch-1

#### Redis

To create a Redis instance for the current space.

    cf marketplace -s redis
    cf create-service redis tiny-5.x psd-queue
    cf create-service redis tiny-5.x psd-session

The current worker (Sidekiq), which uses `psd-queue` only works with an unclustered instance of Redis.

#### S3

When setting up a new environment, you'll also need to create an AWS user called `psd-<<SPACE>>` and keep a note of the Access key ID and secret access key.
Give this user the AmazonS3FullAccess policy.

Create an S3 bucket named `psd-<<SPACE>>`.

#### PSD Website

Start by setting up the following credentials:

* To configure rails to use the production database amongst other things and set the server's encryption key (generate a new value by running `rake secret`):

```
    cf cups psd-rails-env -p '{
        "RAILS_ENV": "production",
        "SECRET_KEY_BASE": "XXX"
    }'
```

* To configure AWS (see the S3 section [above](#s3) to get these values):

```
    cf cups psd-aws-env -p '{
        "AWS_ACCESS_KEY_ID": "XXX",
        "AWS_SECRET_ACCESS_KEY": "XXX",
        "AWS_REGION": "XXX",
        "AWS_S3_BUCKET": "XXX"
    }'
```

* To configure Notify for email sending and previewing (see the GOV.UK Notify account section in [the root README](../README.md#gov.uk-notify) to get this value):

```
    cf cups psd-notify-env -p '{
        "NOTIFY_API_KEY": "XXX"
    }'
```

* To set pgHero http auth username and password for (see confluence for values):

```
    cf cups psd-pghero-env -p '{
        "PGHERO_USERNAME": "XXX",
        "PGHERO_PASSWORD": "XXX"
    }'
```

* To configure Sentry (see the Sentry account section in [the root README](../README.md#sentry) to get these values):

```
    cf cups psd-sentry-env -p '{
        "SENTRY_DSN": "XXX",
        "SENTRY_CURRENT_ENV": "<<SPACE>>"
    }'
```

* To enable and add basic auth to the entire application (useful for deployment or non-production environments):

```
    cf cups psd-auth-env -p '{
        "BASIC_AUTH_USERNAME": "XXX",
        "BASIC_AUTH_PASSWORD": "XXX"
    }'
```

* To enable and add basic auth to the health check endpoint at `/health/all`:

```
    cf cups psd-health-env -p '{
        "HEALTH_CHECK_USERNAME": "XXX",
        "HEALTH_CHECK_PASSWORD": "XXX"
    }'
```

* To enable and add basic auth to the sidekiq monitoring UI at `/sidekiq`:

```
    cf cups psd-sidekiq-env -p '{
        "SIDEKIQ_USERNAME": "XXX",
        "SIDEKIQ_PASSWORD": "XXX"
    }'
```

Once all the credentials are created, the app can be deployed using:

    SPACE=<<space>> ./deploy.sh

### GOV.UK Platform as a Service

You'll need an account for [GOV.UK PaaS](https://admin.london.cloud.service.gov.uk/) to manage deployed instances.

### Other infrastructure

#### Environment variables

We're using [user-provided services](https://docs.cloudfoundry.org/devguide/services/user-provided.html#deliver-service-credentials-to-an-app) to load environment variables into our applications.

The app's `.profile` [automatically initialises](https://docs.cloudfoundry.org/devguide/deploy-apps/deploy-app.html#profile) environment variables using [get-env-from-vcap.sh](./infrastructure/env/get-env-from-vcap.sh) as part of the application startup. This will add credentials from any service named `*-env` to the current environment.

#### Domains

We've setup our domains based on [the instructions provided by PaaS](https://docs.cloud.service.gov.uk/deploying_services/use_a_custom_domain).
This also enables a CDN for the URL so it's important that the `Cache-Control` header is being set correctly.

For each domain, we define a `<<SPACE>>` and `<<SPACE>>-temp` subdomain for hosting and blue-green deployments.

It's important that we also allow the `Authorization` header through the CDN for the basic auth on non-production environments, `Accept` for content-type negotiation, and the `Referer` header for Rails' `redirect_back`.
The following command can be used to create the `cdn-route` service:

    cf create-service cdn-route cdn-route opss-cdn-route -c '{"domain": "<<domain1>>,<<domain2>>", "headers": ["Accept", "Authorization", "Referer"]}'
