# DNS

DNS for subdomains pointed at the GOV.UK PaaS is configured in AWS Route 53.
The subdomain is then added via the Cloud Foundry CLI to set it up as an
endpoint for the automatically configured CloudFront instance and route it
to the relevant app.

## Add new subdomain

To add a new subdomain:

1. Using the Cloud Foundry CLI, log in and choose the relevant space
1. Run `cf service opss-cdn-route` - this will return information about
   the service including a section named "Showing status of last operation"
   that has a list of already-configured subdomains for the current
   environment
1. Run `cf update-service opss-cdn-route -c '{"domain": "<domains>", "headers": ["Accept", "Authorization", "Referer", "Host", "User-Agent"]}'`
   where `<domains>` is a comma-separated list of the domains from the
   previous step plus the new subdomain you want to add
1. Run `cf service opss-cdn-route` again - the "Showing status of last operation"
   section will now detail the records that are required for the new
   subdomain - one to point to CloudFront and one for TLS validation
1. Go to AWS Route 53, select the relevant hosted zone, then add the two
   `CNAME` records as detailed in the previous step
1. Within a few minutes, CloudFoundry will detect the new records,
   add the subdomain to the CloudFront distribution and provision the
   TLS certificate
