# Product safety database

Demo do not merge.

Built by the [Office for Product Safety and Standards](https://www.gov.uk/government/organisations/office-for-product-safety-and-standards)

For enquiries, contact [opss.enquiries@beis.gov.uk](opss.enquiries@beis.gov.uk)

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

See [contributing](CONTRIBUTING.md).

## Amazon Web Services

We're using AWS for file storage on the S3 service. You'll need AWS account credentials.

## Deployment

See [deployment](doc/deployment.md).

## Logging and monitoring

See [logging and monitoring](doc/logging-and-monitoring.md).

## Using Cloud Foundry

See [Cloud Foundry reference](doc/using-cloud-foundry.md).

## Running Tasks

See [Tasks](doc/tasks.md).

## Related projects

### Antivirus API

See [antivirus repo](https://github.com/UKGovernmentBEIS/beis-opss-antivirus).

### Maintenance page

See [maintenance in infrastructure repo](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure/blob/master/maintenance/README.md).

### Other infrastructure

See [infrastructure repository](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure).

## Licence

Unless stated otherwise, the codebase is released under the MIT License. This covers both the codebase and any sample code in the documentation.

The documentation is © Crown copyright and available under the terms of the Open Government 3.0 licence.
