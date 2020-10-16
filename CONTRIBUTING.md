# Contributing
This project is made available as open source, and we welcome contributions from the public. The Department also employs a team dedicated to improving the product. The product team are the maintainers of the codebase and responsible for reviewing and merging contributions.

In order to propose a change to the codebase, you can open a pull request on GitHub.

## Opening Pull Requests
1. Try to only open one pull request at a time. Address feedback on your pull request before working on other changes.
1. If you are a member of the product team, add a link to the relevant team Trello card at the top of the description, if applicable, to give the reader the context of the change.
1. Otherwise, detail the nature of the change in the description.
1. In order to help the reader understand your intent, write a paragraph explaining your approach, and any key choices you made.
1. Include screenshots in your description where there are visual changes.
1. Review the checklist template and *remove* any items which are not relevant.
1. If your pull request is not yet ready for review, please open it as a draft or prepend "[WIP]" to the title. Change the status to open or remove "[WIP]" when your PR is ready for review.
1. There are automated checks on pull requests. All checks must pass before a pull request may be approved or merged.
1. If you are a member of the product team, notify relevant people on the team Slack instance when requesting their review, and add them as reviewers on GitHub.

## Reviewing Pull Requests
### Reviewers
1. Refer to any linked Trello ticket for story context and acceptance criteria.
1. Refer to the checklist on the pull request.
1. Use the wording "please change" when a change is required, and "suggestion" when a change is optional.
1. Use the suggestion feature to demonstrate with code where practical.
1. Use the GitHub review workflow and either approve or request changes.
1. Check the deployed review application and test the changes.

### Authors
1. Respond to change requests/suggestions with a rationale if you disagree.
1. Make any changes as may be requested by peers.
1. Only merge your changes once the relevant approvals have been gathered and recorded on the pull request.
1. The maintainers may close your pull request if it does not meet the expected quality, if feedback is not addressed, or if it does not align with the product team's goals.

## Style guide
1. Prioritise readability.
1. All new code must be supported by a feature spec and relevant unit specs. Write a new feature spec if one does not already exist.
1. Feature specs should only cover "happy path" scenarios and some basic error states. Edge cases and exhaustive error testing should be performed in the relevant unit tests.
1. Use full paths in feature specs - not Rails URL helpers - in order to test the full stack from the user's perspective.
1. Use services to encapsulate business processes, and models for data integrity. Controllers should deal with interactions between the user and services. We use the [interactor](https://github.com/collectiveidea/interactor) gem for composing services. Avoid using organizers to reduce complexity.
1. Use the ERb templating language for view templates. Slim templates are deprecated and should be converted to ERb when possible.
1. Use components and patterns from the [GOV.UK Design System](https://design-system.service.gov.uk) where appropriate. The CSS and JavaScript assets are imported directly from [`govuk-frontend`](https://github.com/alphagov/govuk-frontend), and the
macros have been ported as [Rails compatible components](https://github.com/UKGovernmentBEIS/govuk-design-system-rails).
