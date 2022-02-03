#!/bin/bash

set -e

if [[ ! $VCAP_SERVICES ]]; then
    >&2 echo "\$VCAP_SERVICES not found"
    exit 1
fi

export PGHOST=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .host")
export PGPORT=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .port")
export PGDATABASE=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .name")
export PGUSER=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .username")
export PGPASSWORD=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .password")

export AWS_ACCESS_KEY_ID=$(echo $VCAP_SERVICES | ./jq -r ".\"user-provided\"[] | select(.name|test(\"$ENV_NAME\")) .credentials .REDEX_AWS_KEY_ID")
export AWS_SECRET_ACCESS_KEY=$(echo $VCAP_SERVICES | ./jq -r ".\"user-provided\"[] | select(.name|test(\"$ENV_NAME\")) .credentials .REDEX_AWS_SECRET_KEY")
export AWS_DEFAULT_REGION=$(echo $VCAP_SERVICES | ./jq -r ".\"user-provided\"[] | select(.name|test(\"$ENV_NAME\")) .credentials .REDEX_AWS_REGION")
export AWS_BUCKET=$(echo $VCAP_SERVICES | ./jq -r ".\"user-provided\"[] | select(.name|test(\"$ENV_NAME\")) .credentials .REDEX_AWS_S3_BUCKET")

# NOTE: The apt buildpack installs into a non-globally-writable directory, so explicit paths
#   must be used: https://stackoverflow.com/questions/68861126/getting-an-error-when-running-pg-dump-on-cloud-foundry#comment121702201_68861126
export PERL5LIB=/home/vcap/deps/0/apt/usr/lib/x86_64-linux-gnu:/home/vcap/deps/0/apt/usr/share/perl5:$PERL5LIB
export PYTHONPATH=/home/vcap/deps/0/apt/usr/lib/python3/dist-packages:$PYTHONPATH

TIMESTAMP=$(date +'%F-%H-%M-%S')
FINAL_S3_URL="s3://${AWS_BUCKET}/${TIMESTAMP}.sql.gz"

set -x

/home/vcap/deps/0/apt/usr/lib/postgresql/13/bin/psql < create_redacted_schema.sql
/home/vcap/deps/0/apt/usr/lib/postgresql/13/bin/pg_dump --table='redacted.*' --file=psd_redacted_export.sql --no-acl --no-owner --quote-all-identifiers --format=p --inserts --encoding=UTF8
gzip --keep psd_redacted_export.sql
aws s3 cp psd_redacted_export.sql.gz $FINAL_S3_URL

echo "TASK SCRIPT COMPLETED"
