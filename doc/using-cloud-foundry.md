### Cloud Foundry reference

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
