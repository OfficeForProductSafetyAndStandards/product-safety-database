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

We're using ERB ~~[Slim](http://slim-lang.com/)~~(moving away from it) as our HTML templating language, ES6 JavaScript and [Sass](https://sass-lang.com/) for styling compiled with webpacker.

We're using [Sidekiq](https://github.com/mperham/sidekiq) as our background processor to do things like send emails and handle attachments.

We're processing attachments using our [antivirus API](https://github.com/UKGovernmentBEIS/beis-opss-antivirus) for antivirus checking and [Imagemagick](http://imagemagick.org) for thumbnailing.


## Getting set up

See [getting set up](doc/getting-set-up.md).

## Contributing

See [contributing](CONTRIBUSING.md).

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


## Deployment

See [deployment](doc/deployment.md).

#### Logging

##### Fluentd

We're using [fluentd](https://www.fluentd.org/) to aggregate the logs and send them to both an [ELK stack](https://www.elastic.co/elk-stack) and S3 bucket for long term storage.

#### Logit

We're using [Logit](https://logit.io) as a hosted ELK stack.
If you want to view the logs, you'll need an account - ask someone on the team to invite you.
You should sign up using GitHub OAuth to ensure MFA.

[logstash-filters.conf](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure/blob/master/logstash-filters.conf) provides a set of rules which logstash can use to parse logs.


#### S3

We're using AWS S3 as a long term storage for logs.
See [AWS section](#amazon-web-services) for more details about setting up an account.


### Monitoring

#### Metrics

Our metrics are sent to an ELK stack and S3 using [the paas-metric-exporter app](./paas-metric-exporter).

We have set up a regular job to query the database and to print certain metrics into the logs. This was all done in [PR #962](https://github.com/UKGovernmentBEIS/beis-opss/pull/962).
The metrics are sent in JSON format and logstash is clever enough to split these out into separate logs for each key-value pair.
However, you will need to add an extra filter in [logstash-filters.conf](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure/blob/master/logstash-filters.conf), in order to create new fields on the logs instead of the data all being captured in the `message` field.

### Clound Foundry reference

#### Useful examples

Please take a look into github actions in `.github/workflows` to see how deployments are done.

#### Login to CF Api

```
cf7 login -a api.london.cloud.service.gov.uk -u some@email.com
```

#### SSH to service and run rails console

```
cf7 ssh APP-NAME

cd app && export $(./env/get-env-from-vcap.sh) && /tmp/lifecycle/launcher /home/vcap/app 'rails c' ''
```

#### List apps

```
cf7 apps
```

#### Show app details

```
cf7 app APP-NAME
```

#### Show app env

```
cf7 env APP-NAME
```

#### List services

```
cf7 apps
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
