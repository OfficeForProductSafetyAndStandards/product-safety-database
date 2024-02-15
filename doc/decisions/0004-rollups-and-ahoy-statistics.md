# 3. Rollups and Ahoy Statistics

Date: 22 January 2024

Status: Accepted

## Context

Statistics and usage data is currently being collected by Google Analytics, but not read or analysed by anyone in OPSS. We can't link the user's visit and tracking data with the data we have in our systems, so we can't use it to improve the service or to understand how users are using the service.

We have a requirement to collect usage and feedback data for the service, and to report on the costs of the service. We also have a requirement to collect usage data for the service to help us understand how users are using the service, and to help us improve the service. We wanted to do all of this first-party and not rely on third-party services, additional cookies, or additional tracking - we wanted to use the data we already have.

## Decision

PSD will use [Ahoy](https://github.com/ankane/ahoy) to collect usage data for the service. Ahoy is an MIT licensed Ruby gem that collects usage and visitor data in a first-party database table alongside all the other PSD data. We will use the data in this table to report on the costs of the service, and to understand how users are using the service. We use anonymity sets to anonymise the visitor data in the table, and we will not use the data to identify individual users - therefore we do not need to ask for consent to collect this data, and we do not need to provide a way for users to opt-out of this data collection.

PSD will also use [Rollup](https://github.com/ankane/rollup) to aggregate time series PSD data and Ahoy tracking data. Rollup is an MIT licensed Ruby gem that aggregates data into a separate table that can be used to report on the costs of the service. A scheduled cron task will be setup to run the `bin/rails rollups:generate` task every day. This task will aggregate the data from the previous day into the `rollups` table. The `rollups` table is then read from to query the data for reporting purposes.

A full list of aggregated data sets are available by running `Rollup.list` within the Rails console of PSD.


Pros
----
* Ahoy prevents the need for additional cookies or tracking
* Ahoy allows us to collect usage data for the service
* Rollup allows us to aggregate time series data for reporting purposes
* Both allow us to provide the statuory reporting required by the GDS Service Standard

Cons
----
* Ahoy and Rollup are additional dependencies that need to be maintained
* A daily cron task is required to run Rollup

## Alternatives

Using Google Analytics to collect usage data for the service. This would require additional cookies and tracking, and would not allow us to link the usage data with the data we have in our systems.

## Consequences

There are no significant consequences.
