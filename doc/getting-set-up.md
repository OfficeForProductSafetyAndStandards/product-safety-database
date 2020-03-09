# Getting set up

The application and all of its dependencies can be run with Docker Compose. Alternatively, you can run the application and most dependencies locally.

During development it can be more convenient to run the application locally. In this instance you might find it most convenient to run some of the dependencies, such as Keycloak and Antivirus via Docker, and others, such as Redis and PostgreSQL, locally. This will depend on your own preferences.

## Docker

Install Docker: https://docs.docker.com/install/.

Build and start-up the project, _optionally_ specifying only the services you require, for example:

    docker-compose up keycloak antivirus elasticsearch

Refer to the `docker-compose.yml` file for a list of available services.

## Running the application locally

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

## GOV.UK Notify

If you want to send emails from your development instance, or update any API keys for the deployed instances, you'll need an account for [GOV.UK Notify](https://www.notifications.service.gov.uk) - ask someone on the team to invite you.


## Keycloak

The development instance of Keycloak is configured with the following default user accounts:

* Internal user: `user@example.com` / `password`
* Trading Standards user: `msa@example.com` / `password`
* Admin Console: `admin` / `admin`

Log in to the [Keycloak admin console](http://keycloak:8080/auth/admin) to add/edit users or to obtain client credentials.

Ask someone on the team to create an account for you on the Int and Staging environments.


## Tests
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
