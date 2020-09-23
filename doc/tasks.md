# Tasks

Running Rake tasks against live environments can be done using the `cf run-task` command. For more information, refer to the [CloudFoundry docs](https://docs.cloudfoundry.org/devguide/using-tasks.html).

## Create a new organisation, team, and team admin user

```bash
cf run-task psd-web "export \$(./env/get-env-from-vcap.sh) && ORG_NAME=<name> ADMIN_EMAIL=<email address> bin/rake organisation:create" --name <task name>
```

Where `ORG_NAME` is the name of the organisation and team to be created, and `ADMIN_EMAIL` is the email address of the new team admin user to be created. They will receive an invitation email to create their account. Task name can be set to anything you like.

## Deleting a User

```bash
cf run-task psd-web "export \$(./env/get-env-from-vcap.sh) && EMAIL=<email address> rake user:delete" --name <task name>
```

or

```bash
cf run-task psd-web "export \$(./env/get-env-from-vcap.sh) && ID=<user ID> rake user:delete" --name <task name>
```

Where `EMAIL` or `ID` is the e-mail address or ID of the user to be deleted. Task name can be set to anything you like.

## Deleting a Team

```bash
cf run-task psd-web "export \$(./env/get-env-from-vcap.sh) && ID=<id> NEW_TEAM_ID=<id> EMAIL=<email address> rake team:delete" --name <task name>
```

Case collaborations and users which belong to the team identified by `ID` will be migrated to another team identified by `NEW_TEAM_ID`. The user identified by `EMAIL` will be attributed to the change on all relevant audit activity.
