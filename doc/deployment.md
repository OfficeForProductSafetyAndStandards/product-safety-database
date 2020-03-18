## Deployment

Create your changes in a new branch and open a pull request.

Pull requests trigger a deployment to the `int` space on GOV.UK PaaS of a temporary review application, which is then deleted when the PR is merged. The review application can be viewed at https://psd-pr-XXXX-web.london.cloudapps.digital/ (where XXXX is the PR number).

Merging requires passing tests, code style checks and at least one approving review.

The `master` branch represents our staging and production environments. Anything merged into `master` will trigger a deployment to staging, and then production automatically.


### Review applications

In order to make the PR review process fast and independent, it is possible to create a short lived environment for a given change. In order to create your environment, run `REVIEW_INSTANCE_NAME=ticket-123 ./psd-web/deploy-review.sh`, where `ticket-123` is desired name of review app.

By default, the database is shared, but it can be overriden by setting the `DB_NAME` env variable. This will create a new database instance, however this can take several minutes.

#### Debuging review application

Please run debug app deployment locally. See [".github/workflows/review-apps.yml"](https://github.com/UKGovernmentBEIS/beis-opss-psd/blob/master/.github/workflows/review-apps.yml) for details.


### Deployment from scratch

Once you have a GOV.UK PaaS account as mentioned above, you should install the Cloud Foundry CLI v7 beta (`cf7`) from https://docs.cloudfoundry.org/cf-cli/v7.html and then run the following commands:

    cf7 login
    cf7 target -o beis-opss

This will log you in and set the correct target organisation.

If you need to create a new environment, you can run `cf7 create-space SPACE-NAME`, otherwise, select the correct space using `cf7 target -o beis-opss -s SPACE-NAME`.

#### Database

To create a database for the current space:

    cf7 marketplace -s postgres
    cf7 enable-service-access postgres
    cf7 create-service postgres small-10.5 psd-database


#### Elasticsearch

To create an Elasticsearch instance for the current space:

    cf7 marketplace -s elasticsearch
    cf7 create-service elasticsearch tiny-6.x psd-elasticsearch


#### Redis

To create a redis instance for the current space.

    cf7 marketplace -s redis
    cf7 create-service redis tiny-3.2 psd-queue
    cf7 create-service redis tiny-3.2 psd-session

The current worker (sidekiq), which uses `psd-queue` only works with an unclustered instance of redis.


#### S3

When setting up a new environment, you'll also need to create an AWS user called `psd-<<SPACE>>` and keep a note of the Access key ID and secret access key.
Give this user the AmazonS3FullAccess policy.

Create an S3 bucket named `psd-<<SPACE>>`.


#### PSD Website

This assumes that you've run [the deployment from scratch steps for Keycloak](https://github.com/UKGovernmentBEIS/beis-opss-keycloak#deployment-from-scratch)

Start by setting up the following credentials:

* To configure rails to use the production database amongst other things and set the server's encryption key (generate a new value by running `rake secret`):

```
    cf7 cups psd-rails-env -p '{
        "RAILS_ENV": "production",
        "SECRET_KEY_BASE": "XXX"
    }'
```

* To configure AWS (see the S3 section [above](#s3) to get these values):

```
    cf7 cups psd-aws-env -p '{
        "AWS_ACCESS_KEY_ID": "XXX",
        "AWS_SECRET_ACCESS_KEY": "XXX",
        "AWS_REGION": "XXX",
        "AWS_S3_BUCKET": "XXX"
    }'
```

* To configure Notify for email sending and previewing (see the GOV.UK Notify account section in [the root README](../README.md#gov.uk-notify) to get this value):

```
    cf7 cups psd-notify-env -p '{
        "NOTIFY_API_KEY": "XXX"
    }'
```

* To set pgHero http auth username and password for (see confluence for values):

```
    cf7 cups psd-pghero-env -p '{
        "PGHERO_USERNAME": "XXX",
        "PGHERO_PASSWORD": "XXX"
    }'
```

* To configure Sentry (see the Sentry account section in [the root README](../README.md#sentry) to get these values):

```
    cf7 cups psd-sentry-env -p '{
        "SENTRY_DSN": "XXX",
        "SENTRY_CURRENT_ENV": "<<SPACE>>"
    }'
```

* To enable and add basic auth to the entire application (useful for deployment or non-production environments):

```
    cf7 cups psd-auth-env -p '{
        "BASIC_AUTH_USERNAME": "XXX",
        "BASIC_AUTH_PASSWORD": "XXX"
    }'
```

* To enable and add basic auth to the health check endpoint at `/health/all`:

```
    cf7 cups psd-health-env -p '{
        "HEALTH_CHECK_USERNAME": "XXX",
        "HEALTH_CHECK_PASSWORD": "XXX"
    }'
```

* To enable and add basic auth to the sidekiq monitoring UI at `/sidekiq`:

```
    cf7 cups psd-sidekiq-env -p '{
        "SIDEKIQ_USERNAME": "XXX",
        "SIDEKIQ_PASSWORD": "XXX"
    }'
```

* `psd-keycloak-env` should already be setup from [the keycloak steps](https://github.com/UKGovernmentBEIS/beis-opss/blob/master/keycloak/README.md#setup-clients).

Once all the credentials are created, the app can be deployed using:

    SPACE=<<space>> ./psd-web/deploy.sh

### GOV.UK Platform as a Service

You'll need an account for [GOV.UK PaaS](https://admin.london.cloud.service.gov.uk/) to manage deployed instances.


### Other infrastructure

#### Environment variables

We're using [user-provided services](https://docs.cloudfoundry.org/devguide/services/user-provided.html#deliver-service-credentials-to-an-app) to load environment variables into our applications.

Running [get-env-from-vcap.sh](./infrastructure/env/get-env-from-vcap.sh) as part of the application startup will add credentials from any service named `*-env` to the current environment.

#### Domains

We've setup our domains based on [the instructions provided by PaaS](https://docs.cloud.service.gov.uk/deploying_services/use_a_custom_domain).
This also enables a CDN for the URL so it's important that the `Cache-Control` header is being set correctly.

For each domain, we define a `<<SPACE>>` and `<<SPACE>>-temp` subdomain for hosting and blue-green deployments.

It's important that we also allow the `Authorization` header through the CDN for the basic auth on non-production environments.
The following command can be used to create the `cdn-route` service:

    cf7 create-service cdn-route cdn-route opss-cdn-route -c '{"domain": "<<domain1>>,<<domain2>>", "headers": ["Authorization"]}'
