# Product safety database

Built by the [Office for Product Safety and Standards](https://www.gov.uk/government/organisations/office-for-product-safety-and-standards)

For enquiries, contact [OPSS.enquiries@beis.gov.uk](OPSS.enquiries@beis.gov.uk)

![](https://github.com/UKGovernmentBEIS/beis-opss-psd/workflows/RSpec%20test%20suite/badge.svg?branch=master)
![](https://github.com/UKGovernmentBEIS/beis-opss-psd/workflows/Minitest%20test%20suite/badge.svg?branch=master)
![](https://github.com/UKGovernmentBEIS/beis-opss-psd/workflows/System%20Tests/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/UKGovernmentBEIS/beis-opss-psd/badge.svg?branch=master)](https://coveralls.io/github/UKGovernmentBEIS/beis-opss-psd?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/233b845a516a9c2eecea/maintainability)](https://codeclimate.com/github/UKGovernmentBEIS/beis-opss-psd/maintainability)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=UKGovernmentBEIS/beis-opss-psd)](https://dependabot.com)

## Overview

The application is written in [Ruby on Rails](https://rubyonrails.org/).

We're using [Slim](http://slim-lang.com/) as our HTML templating language, ES6 JavaScript and [Sass](https://sass-lang.com/) for styling compiled with webpacker.

We're using [Sidekiq](https://github.com/mperham/sidekiq) as our background processor to do things like send emails and handle attachments.

We're processing attachments using our [antivirus API](https://github.com/UKGovernmentBEIS/beis-opss-antivirus) for antivirus checking and [Imagemagick](http://imagemagick.org) for thumbnailing.


## Getting set up

The application and all of its dependencies can be run with Docker Compose. Alternatively, you can run the application and most dependencies locally.

During development it can be more convenient to run the application locally. In this instance you might find it most convenient to run some of the dependencies, such as Keycloak and Antivirus via Docker, and others, such as Redis and PostgreSQL, locally. This will depend on your own preferences.

### Docker

Install Docker: https://docs.docker.com/install/.

Build and start-up the project, _optionally_ specifying only the services you require, for example:

    docker-compose up keycloak antivirus elasticsearch

Refer to the `docker-compose.yml` file for a list of available services.

### Running the application locally

You will need to have Redis, PostgreSQL and Elasticsearch running, either locally or via Docker as detailed above.

Copy the file in the `psd-web` directory called `.env.development.example` to `.env.development`, and modify as appropriate.
You will need to set `KEYCLOAK_CLIENT_SECRET` value corresponding to `KEYCLOAK_CLIENT_ID` value. The client secret is accessible through the Keycloak admin console.

See the [accounts section](#accounts) below for information on how to obtain some of the optional variables.

Within the `psd-web` directory:

Install the dependencies:

    bundle install

Create and populate the database:

    bin/rake db:setup

Start the services:

    bin/rails s
    bin/sidekiq -C config/sidekiq.yml


### Tests
Copy the file in the `psd-web` directory called `.env.test.example` to `.env.test`, and modify as appropriate.

New tests are written in RSpec. There should be a feature spec covering new user journeys, and unit testing of all code components.

    bundle exec rspec

There is also a legacy test suite written with Minitest. This is deprecated and tests are being gradually moved over to RSpec. To run it:

    bin/rails test

You can run the Ruby linting with `bin/rubocop`. Running this with the `-a` flag set will cause Rubocop to attempt to fix as many of the issues as it can.

You can run the Slim linting with `bin/slim-lint app`.

You can run the Sass linting with `bin/yarn sass-lint -vq 'app/**/*.scss'`.

You can run the JavaScript linting with `bin/yarn eslint app config`.

You can run the security vulnerability static analysis with `bin/brakeman --no-pager`.


## Design system

This project uses the [GOV.UK design system](https://design-system.service.gov.uk). The CSS and JavaScript assets are imported directly, and the
macros have been ported as [Rails compatible components](https://github.com/UKGovernmentBEIS/govuk-design-system-rails).


## Accounts

### Keycloak

The development instance of Keycloak is configured with the following default user accounts:

* Internal user: `user@example.com` / `password`
* Trading Standards user: `msa@example.com` / `password`
* Admin Console: `admin` / `admin`

Log in to the [Keycloak admin console](http://keycloak:8080/auth/admin) to add/edit users or to obtain client credentials.

Ask someone on the team to create an account for you on the Int and Staging environments.


## GOV.UK Notify

If you want to send emails from your development instance, or update any API keys for the deployed instances, you'll need an account for [GOV.UK Notify](https://www.notifications.service.gov.uk) - ask someone on the team to invite you.


## GOV.UK Platform as a Service

If you want to update any of the deployed instances, you'll need an account for [GOV.UK PaaS](https://admin.london.cloud.service.gov.uk/) - ask someone on the team to invite you.


## Amazon Web Services

We're using AWS for file storage on the S3 service. You'll need an account - ask someone on the team to invite you. If you get an error saying you don't have permission to set something, make sure you have MFA set up.


## Contributing & Deployment

Create your changes in a new branch and open a pull request.

Pull requests trigger a deployment to the `int` space on GOV.UK PaaS of a temporary review application, which is then deleted when the PR is merged. The review application can be viewed at https://psd-pr-<PR NUMBER>-web.london.cloudapps.digital/. Ask someone on the team for the authentication credentials to access this.

Merging requires passing tests, code style checks and at least one approving review.

The `master` branch represents our staging and production environments. Anything merged into `master` will trigger a deployment to staging, and then production automatically.


### Review applications

In order to make the PR review process fast and independent, it is possible to create a short lived environment for a given change. In order to create your environment, run `REVIEW_INSTANCE_NAME=ticket-123 ./psd-web/deploy-review.sh`, where `ticket-123` is desired name of review app.

By default, the database is shared, but it can be overriden by setting the `DB_NAME` env variable. This will create a new database instance, however this can take several minutes.

#### Debuging review application

Please run debug app deployment locally. See [".github/workflows/review-apps.yml"](https://github.com/UKGovernmentBEIS/beis-opss-psd/blob/master/.github/workflows/review-apps.yml) for details.


### Deployment from scratch

Once you have a GOV.UK PaaS account as mentioned above, you should install the Cloud Foundry CLI (`cf`) from https://github.com/cloudfoundry/cli#downloads and then run the following commands:

    cf login
    cf target -o beis-opss

This will log you in and set the correct target organisation.

If you need to create a new environment, you can run `cf create-space SPACE-NAME`, otherwise, select the correct space using `cf target -o beis-opss -s SPACE-NAME`.

#### Database

To create a database for the current space:

    cf marketplace -s postgres
    cf enable-service-access postgres
    cf create-service postgres small-10.5 psd-database


#### Elasticsearch

To create an Elasticsearch instance for the current space:

    cf marketplace -s elasticsearch
    cf create-service elasticsearch tiny-6.x psd-elasticsearch


#### Redis

To create a redis instance for the current space.

    cf marketplace -s redis
    cf create-service redis tiny-3.2 psd-queue
    cf create-service redis tiny-3.2 psd-session

The current worker (sidekiq), which uses `psd-queue` only works with an unclustered instance of redis.


#### S3

When setting up a new environment, you'll also need to create an AWS user called `psd-<<SPACE>>` and keep a note of the Access key ID and secret access key.
Give this user the AmazonS3FullAccess policy.

Create an S3 bucket named `psd-<<SPACE>>`.


#### PSD Website

This assumes that you've run [the deployment from scratch steps for Keycloak](https://github.com/UKGovernmentBEIS/beis-opss/blob/master/keycloak/README.md#deployment-from-scratch)

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

* `psd-keycloak-env` should already be setup from [the keycloak steps](https://github.com/UKGovernmentBEIS/beis-opss/blob/master/keycloak/README.md#setup-clients).

Once all the credentials are created, the app can be deployed using:

    SPACE=<<space>> ./psd-web/deploy.sh



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

    cf create-service cdn-route cdn-route opss-cdn-route -c '{"domain": "<<domain1>>,<<domain2>>", "headers": ["Authorization"]}'


#### Logging

##### Fluentd

We're using [fluentd](https://www.fluentd.org/) to aggregate the logs and send them to both an [ELK stack](https://www.elastic.co/elk-stack) and S3 bucket for long term storage.

#### Logit

We're using [Logit](https://logit.io) as a hosted ELK stack.
If you want to view the logs, you'll need an account - ask someone on the team to invite you.
You should sign up using GitHub OAuth to ensure MFA.

[logstash-filters.conf](./logstash-filters.conf) provides a set of rules which logstash can use to parse logs.


#### S3

We're using AWS S3 as a long term storage for logs.
See [the root README](../README.md#amazon-web-services) for more details about setting up an account.


### Monitoring

#### Metrics

Our metrics are sent to an ELK stack and S3 using [the paas-metric-exporter app](./paas-metric-exporter).

We have set up a regular job to query the database and to print certain metrics into the logs. This was all done in [PR #962](https://github.com/UKGovernmentBEIS/beis-opss/pull/962).
The metrics are sent in JSON format and logstash is clever enough to split these out into separate logs for each key-value pair.
However, you will need to add an extra filter in [logstash-filters.conf](./logstash-filters.conf), in order to create new fields on the logs instead of the data all being captured in the `message` field.

### Clound Foundry reference

#### Useful examples

Please take a look into github actions in `.github/workflows` to see how deployments are done.

#### Proper executable

If `cf` is not working, try `cf7`

#### Login to CF Api

```
cf login -a api.london.cloud.service.gov.uk -u some@email.com
```

#### SSH to service and run rails console

```
cf ssh APP-NAME

cd app && export $(./env/get-env-from-vcap.sh) && /tmp/lifecycle/launcher /home/vcap/app 'rails c' ''
```

#### List apps

```
cf apps
```

#### Show app details

```
cf app APP-NAME
```

#### Show app env

```
cf env APP-NAME
```

#### List services

```
cf apps
```

## BrowserStack

[![BrowserStack](https://user-images.githubusercontent.com/7760/34738829-7327ddc4-f561-11e7-97e2-2fe0474eaf05.png)](https://www.browserstack.com)

We use [BrowserStack](https://www.browserstack.com) to test our service from a variety of different browsers and systems.

## Related projects

### Antivirus API

See [antivirus repo](https://github.com/UKGovernmentBEIS/beis-opss-antivirus).

### Maintenance page

See [maintenance in infrastructure repo](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure/blob/master/maintenance/README.md).

### Keycloak

See [keycloak repository](https://github.com/UKGovernmentBEIS/beis-opss-keycloak).

### Other infrastructure

See [infrastructure repository](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure).

## Licence

Unless stated otherwise, the codebase is released under the MIT License. This covers both the codebase and any sample code in the documentation.

The documentation is © Crown copyright and available under the terms of the Open Government 3.0 licence.
