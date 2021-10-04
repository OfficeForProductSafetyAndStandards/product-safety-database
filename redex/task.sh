#!/bin/bash

if [[ ! $VCAP_SERVICES ]]; then
    >&2 echo "\$VCAP_SERVICES not found"
    exit 1
fi

echo $VCAP_SERVICES | ./env/jq -r "
    .\"user-provided\"
        | map(
            select(.name[-4:] == \"$ENV_NAME\")
                | .credentials
                | to_entries[]
                | \"\(.key)=\(.value)\"
        )
        | @tsv"

export PGHOST=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .host")
export PGPORT=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .port")
export PGDATABASE=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .name")
export PGUSER=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .username")
export PGPASSWORD=$(echo $VCAP_SERVICES | ./jq -r ".postgres[] | select(.name|test(\"$DB_NAME\")) .credentials .password")
export AWS_ACCESS_KEY_ID=$REDEX_AWS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$REDEX_AWS_SECRET_KEY
export AWS_DEFAULT_REGION=$REDEX_AWS_REGION

# NOTE: The apt buildpack installs into a non-globally-writable directory, so explicit paths
#   must be used: https://stackoverflow.com/questions/68861126/getting-an-error-when-running-pg-dump-on-cloud-foundry#comment121702201_68861126
export PERL5LIB=/home/vcap/deps/0/apt/usr/lib/x86_64-linux-gnu:/home/vcap/deps/0/apt/usr/share/perl5

TIMESTAMP=$(date +'%F-%H-%M-%S')
FINAL_S3_URL="s3://${REDEX_AWS_S3_BUCKET}/${TIMESTAMP}.sql.gz"

/home/vcap/deps/0/apt/usr/lib/postgresql/11/bin/psql < create_redacted_schema.sql
/home/vcap/deps/0/apt/usr/lib/postgresql/11/bin/pg_dump --table='redacted.*' --file=psd_redacted_export.sql --no-acl --no-owner --quote-all-identifiers --format=p --inserts --encoding=UTF8

echo "Copying to $FINAL_S3_URL"

gzip --keep psd_redacted_export.sql
aws s3 cp psd_redacted_export.sql.gz $FINAL_S3_URL

echo "Done."
