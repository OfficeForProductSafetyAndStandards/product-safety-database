# Changelog
All notable changes to this project will be documented in this file.

## 2023-03-01
- Significant service update made to change the way users create products and cases. Products and cases are now two separate entities with associated information, enabling one product to be included in multiple different cases.

## 2020-02-01
- Added 'exporter' as a business type.

## 2020-01-05
- Added ability to track online recall information.

## 2020-12-31
- Updated product barcode field to accept more types of barcodes.

## 2020-12-16
- Added ability to track product markings.

## 2020-11-06
- Added ability to track the authenticity of a product.

## 2020-10-22
- Removed the ability to record meetings as correspondence on a case, due to very low usage of the feature.
- Added a new optional "Brand" field for products, so that this can be captured separately from the product name.

## 2020-10-21
- Added a new optional "Barcode" field to products which is validated and standardised as a 13 digit Global Trade Item Number (GTIN). The existing "Barcode or serial number" field has been renamed to "Other product identifiers", and any existing valid barcodes have been moved to the new field.

## 2020-09-23
- Added case risk level to xls exports.

## 2020-08-13
- Added a follow-up question when adding a risk assessment, asking users whether the case risk level should be updated to match.

## 2020-07-27
- Added the ability to add a team as a collaborator to a case with view only permissions.

## 2020-07-10
- Added the ability to set and update the risk level for the cases.

## 2020-06-26
- Added the ability to edit test results.
- Added a case bar which always shows which case you are viewing across all case pages.
- Fixed a bug where case images were only viewable if your team (or another team in your organisation) was added to a case.

## 2020-06-22
- Moved link for adding meetings, phone calls, emails, test results and corrective actions from the case
  activity page to the case supporting information page.
- Users will be redirected to the pertinent tab instead of the case overview once one of these supporting
  information elements is added to a case.

## 2020-06-19
- Added case owner team and removed complainant details from cases export spreadsheet.
- Only teams added to a case can now view restricted cases

## 2020-06-17
- Only teams added to a case can now view correspondence or attachment details.

## 2020-06-12
- Users of all teams added to a case can now view complainant contact details on the case activity page.

## 2020-06-05
- Added the ability to view the details of correspondence added to the case on their own page.

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
### Product Safety Database
- Filter by case type
- Filter by creator
- New service navigation
- Welcome email
- Product search
- Cookie banner
- Content fixes
- Case ID can now be searched by using an exact match (e.g 1907-001)

## 2019-04-23
### Product Safety Database
- Fixed a bug where the wrong user was attributed to entries in the activity log.
- Improvements to the display of error messages across the service.
- Various bug fixes.


## 2019-04-03
### Product Safety Database
- Update introduction, about page, terms and conditions and privacy notice.


## 2019-03-29
### Product Safety Database
- Rename the service to Product Safety Database.
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
