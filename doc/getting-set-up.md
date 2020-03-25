# Getting set up

## Installing the application

First, clone the Git repository and `cd` into it within a terminal prompt:

```bash
git clone https://github.com/UKGovernmentBEIS/beis-opss-psd.git
cd beis-opss-psd
```

### 1. Install prequisites

The application requires several things to run. Install these:

* [Redis](https://redis.io/download)
* [PostgreSQL](https://www.postgresql.org/download/)
* [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/6.8/install-elasticsearch.html) - version 6 (you can also install this via Docker, see below)

### 1.1 Install prerequsites via Docker

Some of the dependencies are easier to install via [Docker](https://docs.docker.com/install/):

* Keycloak
* Antivirus (optional)

To install these, run this command from the root folder:

```bash
   docker-compose build keycloak
```

and

```bash
   docker-compose build antivirus
```

### 2. Install Ruby and gem dependencies

The application is written in Ruby using the Rails framework.

You need to install the right version of Ruby - see [Gemfile](./psd-web/Gemfile). To do this, you could use either [rvm](https://rvm.io/rvm/install) or [rbenv](https://github.com/rbenv/rbenv) – these allow you to have multiple different versions of Ruby installed at the same time.

Once you’ve installed the right version of Ruby, you can install the Ruby gem dependencies by running this command from `psd-web`:

```bash
   bundle install
```


### 3. Install Node and npm dependencies

Node modules are used for front-end dependencies (CSS, javascript and images).

First install the right version of node using [node version manager](https://github.com/nvm-sh/nvm#installing-and-updating) (nvm). The current version used is specified in the [package.json](./psd-web/package.json) file.

Then install [yarn](https://classic.yarnpkg.com/en/docs/install)

Once these are both installed, run this command from within `psd-web`:

```bash
   yarn install
```

to install npm dependencies.

### 4. Configure your local environment

Some settings are configured within a hidden file called `.env.development` (within the `psd-web` folder). You will need to create this - you can copy the example in [`.env.development.example`](./psd-web/.env.development.example).

You will need to edit this file to add:

* [GOV.UK Notify](https://www.notifications.service.gov.uk) API key
* Keycloak client secret


### 5. Setup the database

Create and populate the database:

```bash
    bundle exec bin/rake db:setup
```

## Running the application

To compile the front-end assets (and have them re-compile as you make changes), run:

```bash
    bundle exec bin/webpack-dev-server
```

Start the application (from `psd-web`):

```bash
    bundle exec bin/rails server
    bundle exec bin/sidekiq
```

### Keycloak

The development instance of Keycloak is configured with the following default user accounts:

* Internal user: `user@example.com` / `password`
* Trading Standards user: `msa@example.com` / `password`
* Admin Console: `admin` / `admin`

Log in to the [Keycloak admin console](http://keycloak:8080/auth/admin) to add/edit users or to obtain client credentials.


## Running the tests

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
