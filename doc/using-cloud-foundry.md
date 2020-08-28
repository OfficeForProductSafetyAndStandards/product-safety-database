### Cloud Foundry reference

#### Useful examples

Please take a look into github actions in `.github/workflows` to see how deployments are done.

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
