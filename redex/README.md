# Redacted Export

This folder contains a separate CloudFoundry app which is used when producing redacted database export.

The app is pushed with the appropriate settings and schema creation script by a GitHub Actions workflow. A task is then run to generate a redacted export and upload it to an S3 bucket.
