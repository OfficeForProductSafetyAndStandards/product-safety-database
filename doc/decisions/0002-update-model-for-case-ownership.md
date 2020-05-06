# 0. Update model for case ownership

Date: `<date>`
Status: [Accepted|Amended by `#`|Retired]

## Context

Our current model for "case ownership" (previously termed "assignee") is that a case can either belong to a user or a team.

This is implemented as a [polymorphic association](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations) from the cases table, with both an `owner_id` and a `owner_type`, which can be `null` (although this state shouldn’t be possible via the application interface).

The permissions model for the service is based upon teams, not users – this is to simplify access management (ie not having to add and remove users to cases), and to guard against a single user with access rights being unexpectedly unavailable.

Because cases can currently be owned by a user instead of a team though, this has meant having to look up the team of that owner in order to determine permissions.

A recent change has also added a 'collaborators' model, which allowed additional teams (as well as the owner team) to be associated with a case.

This gives us an opportunity to rethink the owner relationship, and see if there is a better way to implement the following business rules, and to simplify the code:

* all cases must have a single team which is the owner
* cases can optionally have a single specified user who is assigned to the case

## Decision

tbc (once we've decided)


## Options

### 1. Add foreign keys on the cases table

Rather than having `owner_id` and `owner_type` columns, we could just have an `owner_id` column, and make this non-nullable, and a foreign key association with the primary key of the `teams` table.

An additional `assigned_user_id` column would be needed as a foreign key to the `users` table, but this could be `null`.

Pros
----
* Enforces the requirement that all cases belong to a single team at the database level.
* Clearly separates the user and team relationships.

Cons
----
* Checking whether a team has access to a case would still mean querying two places: the `owner_id` and the `collaborators` table.
* When a the owner of a case is changed to a different team, the application would have to remove the new owner team from the collaborators table (if they were an existing collaborator), add that team as the `owner_id`, and then add the previous owner team to the collaborators table.

### 2. Keep the polymorphic association, but make it non-nullable

This would make the `owner_id` and `owner_type` columns non-nullable.

Pros
----
* Enforces the requirement at database level that all cases at least have an `owner_id` and `owner_type` specified
* Only a small change to make.

Cons
----
* Does not enforce referential integrity (ie the `owner_id` could be invalid or refer to a record that has been deleted)
* Code would still need to check the owner team OR the team of the owner user in order to check permissions, as well as the collaborators table.
* When a the owner of a case is changed to a different team, the application would have to remove the team from the collaborators table (if they were an existing collaborator) and then add the previous team to the collaborators table.

### 3. Add an `owner` boolean column to the collaborators model

This would remove both `owner_id` and `owner_type`, and instead would add an `owner` boolean on the collaborators model, as well as a nullable `assigned_user_id` foreign key on the cases table.

Pros
----
* Moves all of the relationships between cases and teams to a single place (the `collaborators` table), which simplifies querying.
* Changing the case owner team becomes simpler: add or update the new team as a collaborator with the `owner` flag set to `true`, and change the `owner` flag of the previous owner to `false` to downgrade them to a collaboraor.

Cons
----
* The database wouldn’t enforce that all cases have exactly one team owner (it’d be possible to have zero or 2+ team owners), this would have to be done at the application layer.
* Querying for the owner team of the case would require a join rather than a simpler query.

### 4. Polymorphic `Collaborator` model

Adding `assignee_id` and `assignee_type` columns, which will store either `Team` or `User`. Adding `role` column which will store permission level, eg: `owner`, `read_access`, `write_access` etc.

Pros
----
* Moves all of the relationships between cases and teams to a single place (the `collaborators` table)
* Changing the case owner team becomes simpler: by using `role` column we can have fine grained permissions.

Cons
----
* Querying for the owner team of the case would require a join rather than a simpler query.

### 5. Any other alternatives?

Other ideas?

## Consequences

tbc
