# Changelog
All notable changes to this project will be documented in this file.

## 2020-05-26
- Update service guidance to give details of revised permission model on cases.

## 2020-05-26
- Only teams added to a case can view complainant contact details on the case summary page.

## 2020-05-13
- Allow users that haven't verified their mobile number to change their mobile number while requesting a new security code.

## 2020-05-12
- Allow users to request a new security code when the code was not received via SMS.

## 2020-05-08
- Removed the ability for a user to be in more than one team.

## 2020-05-06
- Ability to remove team from case.

## 2020-04-27
- Allow to report a case as safe. Previously one could only report a case as non-compliant, unsafe or both.

## 2020-04-24
- Added the ability to add collaborating teams to a case, who will then be able to view all details, even if the case is restricted.

## 2020-04-16
- Extended the question to identify cases related to the coronavirus outbreak to:
  - Allegations
  - Enquiries
  - Projects

## 2020-04-15
- Added Your account page and ability to change your name

## 2020-04-07
- Added ability to edit the coronavirus related flag

## 2020-04-03
- Added a question for MSA users to identify cases related to the coronavirus outbreak.

## 2020-03-17
- Only enquiries will now display Received by and Received date in the source summary list.

## 2020-03-09
- Fixed City or town not being displayed when adding an address to a business.

## 2020-03-06
- Fixed an error which was displayed when deleting an attachment from a product.

## 2019-08-05
### Product safety database
- Filter by case type
- Filter by creator
- New service navigation
- Welcome email
- Product search
- Cookie banner
- Content fixes
- Case ID can now be searched by using an exact match (e.g 1907-001)

## 2019-04-23
### Product safety database
- Fixed a bug where the wrong user was attributed to entries in the activity log.
- Improvements to the display of error messages across the service.
- Various bug fixes.


## 2019-04-03
### Product safety database
- Update introduction, about page, terms and conditions and privacy notice.


## 2019-03-29
### Product safety database
- Rename the service to Product safety database.
- Add case alert functionality (to send RAPEX-style alerts).
- Add introduction slides, about page, terms and conditions and privacy policy.
- Add terms and conditions declaration prompt.
- Assign cases to their creator by default.
- Allow users to view their team members.
- Allow users to add new team members.
- Various bug fixes.


## 2019-03-07
### MSPSDS
- Make the autocomplete arrow open the list.
- Add the "Create new case" button for TS users.
- Add clear button to autocompletes.
- Increase character limits on text inputs.
- Make error summaries more consistent across pages.
- Add a healthcheck endpoint.
- Enable sidekiq UI.
- Move antivirus to a separate API.
- Send confirmation email to current user on creation of a case.
- Add support for team mailboxes. When a team with one is supposed to be notified, the email will be sent just to
team mailbox, rather than to all of its members.
- Add business type when adding a business to a case.


## 2019-02-21
### General
- Added changelog
