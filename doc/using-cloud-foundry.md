# Cloud Foundry reference

## Useful examples

Please take a look into GitHub actions in `.github/workflows` to see how deployments are done.

### Login to CF Api

```
cf login -a api.london.cloud.service.gov.uk -u some@email.com
```

### SSH to service and run rails console

```
cf ssh APP-NAME
/tmp/lifecycle/launcher /home/vcap/app 'bin/rails c' ''

# There is a shorthand alias:
cd app
bin/tll bin/rails c
```

### Copying data from staging to review apps

```
cf login -a api.london.cloud.service.gov.uk -u EMAIL
cf target -s staging
cf conduit psd-database -- pg_dump --file psd-staging.sql --no-acl --no-owner
cf target -s int
cf create-service postgres tiny-unencrypted-13 NEW_DB_NAME
cf service NEW_DB_NAME # wait until status is `create succeeded` (10-15 mins)
cf conduit NEW_DB_NAME -- psql < psd-staging.sql
cf unbind-service PR_APP_NAME OLD_DB_NAME
cf bind-service PR_APP_NAME NEW_DB_NAME
cf restage PR_APP_NAME
cf ssh PR_APP_NAME -> cd app -> bin/tll bin/rake notifications:index
```

### List apps

```
cf apps
```

### Show app details

```
cf app APP-NAME
```

### Show app env

```
cf env APP-NAME
```

### List services

```
cf services
```
