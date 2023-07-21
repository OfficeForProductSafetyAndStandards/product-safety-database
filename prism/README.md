# PRISM: Product safety risk assessment

PRISM is a product safety risk assessment tool used by market surveillance authorities to assess the risks of products listed in the Product Safety Database (PSD).

Built by the [Office for Product Safety and Standards](https://www.gov.uk/government/organisations/office-for-product-safety-and-standards).

For enquiries, contact [opss.enquiries@beis.gov.uk](mailto:opss.enquiries@beis.gov.uk).

## Getting started

PRISM is accessed from within the PSD application.

To work on PRISM, set up the PSD application as usual, then in the `prism` directory, run `bundle install` and `yarn install`.

## Technical documentation

This is a Ruby on Rails engine packaged as a gem, and is used by the parent PSD application.

It uses ERB for templating along with Sass for styling and ES6 for scripting.

### Migrations

Database migrations are contained in the `db/migrate` directory, but must be copied over to the PSD application before running.
Once your migrations are ready, from the PSD application root, run `bundle exec rails prism:install:migrations`.
You can then run the migrations as usual. All PRISM table names must be prefixed with `prism_` to avoid potential clashes
with PSD tables.

### Antivirus API

The [antivirus API](https://github.com/OfficeForProductSafetyAndStandards/antivirus) is used to virus scan user-uploaded files.

### Accounts

#### GOV.UK Platform as a Service

This application is deployed to [GOV.UK PaaS](https://admin.london.cloud.service.gov.uk/) - ask someone on the team to invite you.

#### GOV.UK Notify

All emails and text messages are sent using [GOV.UK Notify](https://www.notifications.service.gov.uk) - ask someone on the team to invite you.

#### Amazon Web Services

User-uploaded files are saved to AWS S3 - ask someone on the team to invite you.

## Licence

[MIT licence](../LICENSE)

## Acknowledgements

File icons made by [Freepik](https://www.flaticon.com/authors/freepik) from [www.flaticon.com](https://www.flaticon.com).
