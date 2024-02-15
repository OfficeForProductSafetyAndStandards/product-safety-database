# Logging and monitoring

## Logging

### Fluentd

We use [fluentd](https://www.fluentd.org/) to aggregate the logs and send them to both an [ELK stack](https://www.elastic.co/elk-stack) and S3 bucket for long term storage.

### Logit

We use [Logit](https://logit.io) as a hosted ELK stack.

### S3

We use AWS S3 as a long term storage for logs.

## Monitoring

### Sentry

We use [Sentry](https://sentry.io/) to monitor the application, including all reportable exceptions and CSP violations.
