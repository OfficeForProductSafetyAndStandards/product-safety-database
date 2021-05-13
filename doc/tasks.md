# Tasks

Running Rake tasks against live environments can be done using the `cf run-task` command. For more information, refer to the [CloudFoundry docs](https://docs.cloudfoundry.org/devguide/using-tasks.html).

When running a task, using the `--name <task name>` option makes it easier to filter the logs for the output from your task.

The `-k 2G` option specifies a disk quota of 2GB, as the default of 1GB is not currently sufficient.

## Create a new organisation, team, and team admin user

```bash
cf run-task psd-web --command "export \$(./env/get-env-from-vcap.sh) && ORG_NAME=<name> ADMIN_EMAIL=<email address> bin/rake organisation:create" --name <task name> -k 2G
```

Where `ORG_NAME` is the name of the organisation and team to be created, `ADMIN_EMAIL` is the email address of the new team admin user to be created and `COUNTRY` is the country in which the team is based. ( For countries use the ISO codes found [here] (https://github.com/alphagov/govuk-country-and-territory-autocomplete/blob/master/dist/location-autocomplete-canonical-list.json) or the following: England = "country:GB-ENG", Scotland = "country:GB-SCT", Wales = "country:GB-WLS", Northern Ireland = "country:GB-NIR") They will receive an invitation email to create their account. Task name can be set to anything you like.

## Deleting a User

```bash
cf run-task psd-web --command "export \$(./env/get-env-from-vcap.sh) && EMAIL=<email address> rake user:delete" --name <task name> -k 2G
```

or

```bash
cf run-task psd-web --command "export \$(./env/get-env-from-vcap.sh) && ID=<user ID> rake user:delete" --name <task name> -k 2G
```

Where `EMAIL` or `ID` is the e-mail address or ID of the user to be deleted. Task name can be set to anything you like.

## Deleting a Team

```bash
cf run-task psd-web --command "export \$(./env/get-env-from-vcap.sh) && ID=<id> NEW_TEAM_ID=<id> EMAIL=<email address> rake team:delete" --name <task name> -k 2G
```

Case collaborations and users which belong to the team identified by `ID` will be migrated to another team identified by `NEW_TEAM_ID`. The user identified by `EMAIL` will be attributed to the change on all relevant audit activity.

## Migrating audit activity metadata

Sometimes we need to update the structure of metadata stored against an activity type. We provide a task which can be used instead of ActiveRecord migrations to more safely migrate the data asynchronously to avoid problems with deployment timeouts and multiple versions of the code resulting in errors.

```bash
cf run-task psd-web --command "export \$(./env/get-env-from-vcap.sh) && CLASS_NAME=<activity class name> rake activities:update_metadata" --name <task name> -k 2G
```

To implement a conversion, override the `metadata` getter method on the class being changed to return legacy activity metadata in the new format. This task will invoke the overridden getter method and update each instance with the new structure.
