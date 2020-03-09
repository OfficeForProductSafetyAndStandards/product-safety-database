### Logging and monitoring

#### Logging

##### Fluentd

We're using [fluentd](https://www.fluentd.org/) to aggregate the logs and send them to both an [ELK stack](https://www.elastic.co/elk-stack) and S3 bucket for long term storage.

#### Logit

We're using [Logit](https://logit.io) as a hosted ELK stack.
If you want to view the logs, you'll need an account - ask someone on the team to invite you.
You should sign up using GitHub OAuth to ensure MFA.

[logstash-filters.conf](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure/blob/master/logstash-filters.conf) provides a set of rules which logstash can use to parse logs.


#### S3

We're using AWS S3 as a long term storage for logs.
See [AWS section](#amazon-web-services) for more details about setting up an account.


### Monitoring

#### Metrics

Our metrics are sent to an ELK stack and S3 using [the paas-metric-exporter app](./paas-metric-exporter).

We have set up a regular job to query the database and to print certain metrics into the logs. This was all done in [PR #962](https://github.com/UKGovernmentBEIS/beis-opss/pull/962).
The metrics are sent in JSON format and logstash is clever enough to split these out into separate logs for each key-value pair.
However, you will need to add an extra filter in [logstash-filters.conf](https://github.com/UKGovernmentBEIS/beis-opss-infrastructure/blob/master/logstash-filters.conf), in order to create new fields on the logs instead of the data all being captured in the `message` field.
