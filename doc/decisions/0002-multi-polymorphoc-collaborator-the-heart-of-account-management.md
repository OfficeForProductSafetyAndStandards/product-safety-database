## Case Owner / Collaborator models / permissions

As we are going to add more permissions to the application, we need a more flexible and centralised way for out future account management needs.
Some of those permission will be fairly classic _read_/_write access.

### Current situation

the core of the permission rely on what a `User` and/or `Team` can do.
It is import the permission system is resilient enough to not have to know about that the underlying model being a `User` or a `Team`.
This would lead to spagetti code with lots of conditionals all over the place and an exponential complexity of cases to handle.

At the moment we have 3 models that reference either one or both of the `User` and `Team`

1. `Source`
   This model is polymorphic and reference either a `User` or a `Team` via the `Source` and `UserSource` model.
   This model is used as an association on the investigation to identify who has created an investigation.
   It currently set in a very obstructive way and rely on the fact the a user is logged currently logged in or not.
   This makes our tests data brittle since it is very easy not to setup this assiciation correcty.

2. Owner
   This model is polymorphic and reference either a `User` or a `Team` directly.
   This model is used as an association on the investigation to identify who currently owns an investigation.
   Owners, whether it be a user or a team, determines which user or user within a team can re-assign (i.e change ownershio) of an investigation, view or change the certain attributes of and investgation and also add collaborators.

3. Collaborator
   This model is *not* polymorphic and only directly references a `Team`.
   This is the first milestones of a our permission work and was introduced in order to _allow_ other team to collaborate (i.e add view permission) on a *private* investigation.

### Problem with the current system

In order to know what permissions and a team or a user has for a given case, with the current system we potentially have to query 4 or five different tables and deal with object with a completely different interface.


### (multi) Polymorphic Collaborator model

By adding a polymorphic `:collaborating` association we allows a collaborator to reference either a `Team` or a `User` and possibly in the future anther completely different type of collaboration like may and Admin, a cat or a dog it does not matter. As long as all the `:collaborating` referenced relation have a common interface. We can substitute one for another and the `Collaborator` does not need to care if is a `User`, `Team`, a cat or even a dog. This is comonly know as ducktyping in the ruby community but more generaly in the programming community it's the third pricinple of the S.O.L.I.D principles.

We now can reference either a `Team` or `User` via the Collaborator object. But now, how to we model whether a this `:collaborating` reference is a `Source`, `UserSource`, `Owner` or a just a simple `Collaborator`, hence how to establish what set of permission a `:collaborating` object has in regards to an investigation?

This is where polymorphism on `Collaborator` with Single Table Inheritence is here to help. It is pretty obvious by now that each collaborator do not have the same permissions.
After consulting with Ed, with divised a different sets of permissions


There basically three main branches in the hierarchy

```ruby
class Collaborators::Base;
  self.abstract_class = true
  belongs_to :invesitgation
  belongs_to :collaborating, polymorphic: true
end

class Collaborators::Current < Collaborators::Base
  self.abstract_class = true
end

# CaseCreator will replace the Source and SourceUser object.
# right now case creator do not not have any type of permission.
# But this record is useful as we always want to show which user and/or team created the investigation.
# This gracefully handles the case where a user changed teams but created the case when he/she was part of another team.
# This way we do not give extra permissions to these types of collaborator.
# This are also extensively used in audit log, the formerly known :source association
class Collaborators::CaseCreator < Collaborators::Base

# Ed wants to store both to be able to easly display with a label which one which are the creators.
# Currently we store either one or the other, a user or a team.
class Collaborators::CaseCreatorTeam < Collaborators::CaseOwner; end
class Collaborators::CaseCreatorUser < Collaborators::CaseOwner; end


# the owner types
class Collaborators::CaseOwner < Collaborators::Current
  self.abstract_class = true
end
# This allows to assign either a team or user as an owner.
# I've created a services class AssignInvestigation that allows the managing new case owner assignments,
# when assigning a User a CaseOwnerTeam is also created.
# @Ed: what was the rational behing having the two at the same time?
class Collaborators::CaseOwnerTeam < Collaborators::CaseOwner; end
class Collaborators::CaseOwnerUser < Collaborators::CaseOwner; end

# This is your regular collbaborator.
class Collaborator < Collaborators::Current; end

# Ed wants to keep the history of retired collaborator. "Assign to a previously collaborator"
class Collaborators::Historical < Collaborators::Current; end
```

This type of modelling is super flexible has you can retrieve part of the hierarchy tree `investigation.current_collaborators #  => [Collaborator, CaseOwnerTeam, CaseOwnerUser, OtherFuturTypeOfPermission]`
without messing with several boolean columns and complex checking, often order dependent, to determine whether a user or a team has a certain permission. It also avoid boolean flag creap on table (i.e has_accepted_declaration, has_viewed_introduction, has_been_sent_welcome_email, mobile_number_verified... :rofl: which all represent on state of a user can be at time).

It's also flexible enough that is can allow for future collaborator type to be added witout having to add another db field and backfill it.
This also has the flexibily the we might want to scope/override some of the permission for a give type of Collaborator on specific investigation.
```ruby
collaborator.permission = { can_change_owner: true }
```

This class hierarchy will work beautifully with Pundit, as each class with have it own policy class, possibly respecting the Collaborators hierarchy and computing on the fly if any override or special permission has been assigned to a given type of collaborator.

### Freebies(-ish)

We'll have to index ownership slighlty differently. [See these line](https://github.com/UKGovernmentBEIS/beis-opss-psd/pull/586/files#diff-2cb85cf5237b33fabd4731cbac15181fR14-R20)
The gives us to be abilty to perform search against a viewing user. And the search would not show cases you do not have access to.
I think this is a slight hurdle to overcome that will however benefit the user.
