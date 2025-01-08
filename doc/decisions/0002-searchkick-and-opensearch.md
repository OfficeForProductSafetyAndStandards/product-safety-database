# 2. Searchkick and Opensearch

Date: 30 August 2023

Status: Accepted

## Context

In PSD, users can search for cases, businesses and products. Business and Product records are searched via just the database, but cases indexed via opensearch.

PSD used to use elasticsearch for in-app search - and this now uses a proprietary product license. Due to PSD being an open source project, the license is not compatible with the project. On the infrastructure side, we have moved to opensearch, which is a fork of elasticsearch, but the codebase still uses elasticsearch libraries.

Opensearch is a before licence change fork of elasticsearch, and uses the same API broadly. Opensearch is becoming the standard for opensource projects like PSD due to licence compatablility.

Within PSD, there is a lot of custom code involving direct use of elasticsearch libs, including custom concerns and low-level interactions.

This code is very difficult to maintain and change, and is not well tested. It is also not well documented, and is not well understood by the new team.

## Decision

### Opensearch
PSD will use opensearch for all in-app search.

### Searchkick
We have replaced the custom code with the [searchkick](https://github.com/ankane/searchkick) gem, which is a well maintained OSS gem that can use elasticsearch or opensearch engines. It is used in production by many sites & other projects, and is licensed under MIT. All the functionality under PSD is now working under searchkick - it replaces the custom concerns & direct communication with opensearch, and replaces it with a well tested, well documented, well understood ruby gem.

### Active_model_serializers
To manage the search hash serialization of the `Investigation` model, we need to produce a ruby hash of each object. A serilalizer gem allow us to more easily test this contract, extracting it out as it's own object. Testing can therfore be done in isolation, and serializers will be reused for the API work later.

We have chosen to use [active_model_serializers](https://github.com/rails-api/active_model_serializers/tree/0-10-stable) as it is well maintained, and a popular gem for this purpose.

Pros
----
* Removes licence issues around elasticsearch
* Replaces custom code with a well maintained OSS gem
* Allows for future use of more complex opensearch functionality, such as synonyms, facets, similarity search, etc
* Removes all elasticsearch code, giving more certainty around future changes, and to the licence

Cons
----
* Indexes will need to be rebuilt on deploy, as the searchkick gem uses a different index format
* Searchkick is maintained by a third-party developer, and is not part of the core rails team
* Active_model_serializers is maintained by a third-party developer, and is not part of the core rails team
* Any future changes to either gem will need to be managed by the team

## Alternatives

None considered

## Consequences

We will need to rebuild the indexes on deploy, which will take some time. This will be done as part of the deploy process, and will be managed by the team.

Search within PSD will be much the same after this refactor, but allow for future improvements to the search functionality which have been asked for by users and the business
