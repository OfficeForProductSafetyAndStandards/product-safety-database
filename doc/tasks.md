# Tasks

Running Rake tasks against live environments can be done using the `cf run-task` command. For more information, refer to the [CloudFoundry docs](https://docs.cloudfoundry.org/devguide/using-tasks.html).

When running a task, using the `--name <task name>` option makes it easier to filter the logs for the output from your task.

The `-k 2G` option specifies a disk quota of 2GB, as the default of 1GB is not currently sufficient.

## Create a new organisation, team, and team admin user

```bash
cf run-task psd-web --command "ORG_NAME=<name> ADMIN_EMAIL=<email address> bin/rake organisation:create" --name <task name> -k 2G
```

Where `ORG_NAME` is the name of the organisation and team to be created, `ADMIN_EMAIL` is the email address of the new team admin user to be created and `COUNTRY` is the country in which the team is based. ( For countries use the ISO codes found [here] (https://github.com/alphagov/govuk-country-and-territory-autocomplete/blob/master/dist/location-autocomplete-canonical-list.json) or the following: England = "country:GB-ENG", Scotland = "country:GB-SCT", Wales = "country:GB-WLS", Northern Ireland = "country:GB-NIR") They will receive an invitation email to create their account. Task name can be set to anything you like.

## Deleting a User

Use the OSU Support Portal.

## Deleting a Team

```bash
cf run-task psd-web --command "ID=<id> NEW_TEAM_ID=<id> EMAIL=<email address> bin/rake team:delete" --name <task name> -k 2G
```

Case collaborations and users which belong to the team identified by `ID` will be migrated to another team identified by `NEW_TEAM_ID`. The user identified by `EMAIL` will be attributed to the change on all relevant audit activity.

## Migrating audit activity metadata

Sometimes we need to update the structure of metadata stored against an activity type. We provide a task which can be used instead of ActiveRecord migrations to more safely migrate the data asynchronously to avoid problems with deployment timeouts and multiple versions of the code resulting in errors.

```bash
cf run-task psd-web --command "CLASS_NAME=<activity class name> bin/rake activities:update_metadata" --name <task name> -k 2G
```

To implement a conversion, override the `metadata` getter method on the class being changed to return legacy activity metadata in the new format. This task will invoke the overridden getter method and update each instance with the new structure.

## Redacted data export

The service has the ability to export a redacted version of its database, and certain user-uploaded files, to Amazon S3. A [Github Actions workflow](/.github/workflows/publish-staging-redacted-export.yml) is provided for this purpose and this runs on a schedule as well as manually when required. It's also possible to trigger parts of this export via the `redacted_export` rake task.

### Redacting the database

To produce a `.sql` script suitable for redacting the database, and to apply it to produce a redacted database dump:

```bash
bin/rails redacted_export:generate_sql > create_redacted_schema.sql
psql < create_redacted_schema.sql
pg_dump --table='redacted.*' --file=psd_redacted_export.sql --no-acl --no-owner --quote-all-identifiers --format=p --inserts --encoding=UTF8
```

The way to do this on the deployed service is a little different and it's best done by [triggering the workflow manually](https://github.com/OfficeForProductSafetyAndStandards/product-safety-database/actions/workflows/publish-staging-redacted-export.yml), or by following [the steps inside it](/.github/workflows/publish-staging-redacted-export.yml). These perform steps two and three of the above by deploying [a separate CF app](/redex) which has secured access to the database and to S3.

### Copying the user uploaded files

Risk Assessment and Test Result user uploads are also exported to S3. These are copied to a separate bucket using an S3 Batch Operation job. This is usually done as part of the [same workflow which exports the database](/.github/workflows/publish-staging-redacted-export.yml), however it can be triggered manually:

```bash
cf run-task psd-web --command "bin/rails redacted_export:copy_s3_objects" --name <task name> -k 2G --wait
cf logs psd-web --recent
```

This task returns a Job ID, the progress of which can be tracked in the AWS S3 Console.
