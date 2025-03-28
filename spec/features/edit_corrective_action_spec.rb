require "rails_helper"

RSpec.feature "Edit corrective action", :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  include_context "with corrective action setup for updates"
  let(:existing_legislation) { corrective_action.legislation.first }
  let(:has_online_recall_information) { "has_online_recall_information_yes" }

  before do
    investigation.businesses << business_one << business_two
    sign_in user
  end

  context "when a single product is chosen" do
    it "provides a mean to edit a corrective action" do
      visit "/cases/#{investigation.pretty_id}/corrective-actions/#{corrective_action.id}"

      click_link "Edit corrective action"
      expect_to_have_notification_breadcrumbs

      within_fieldset("What action is being taken?") { expect(page).to have_checked_field(CorrectiveAction.actions[corrective_action.action]) }
      expect(page).to have_field("Day", with: corrective_action.date_decided.day)
      expect(page).to have_field("Month", with: corrective_action.date_decided.month)
      expect(page).to have_field("Year", with: corrective_action.date_decided.year)

      within_fieldset("Which product is subject to action?") do
        expect(page).to have_checked_field("#{corrective_action.investigation_product.name} (#{corrective_action.investigation_product.product.psd_ref})")
      end

      expect(page).to have_select("Under which legislation?", selected: corrective_action.legislation)

      within_fieldset("Which business is responsible?") do
        expect(page).to have_checked_field(corrective_action.business.trading_name)
      end

      corrective_action.geographic_scopes.each do |geographic_scope|
        expect(page).to have_checked_field(I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]))
      end

      expect(page).to have_field("Further details (optional)", with: corrective_action.details, type: "textarea")

      within_fieldset("Has the business responsible published product recall information online?") do
        expect(page).to have_checked_field("Yes")
        expect(page).to have_field("Location of recall information", with: corrective_action.online_recall_information)
      end

      measure_type = corrective_action.measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "Yes" : "No, it’s voluntary"

      within_fieldset("Is the corrective action mandatory?") do
        expect(page).to have_checked_field(measure_type)
      end

      within_fieldset("Are there any files related to the action?") do
        expect(page).to have_checked_field("Yes")
        expect(page).to have_unchecked_field("Remove attached file")
        expect(page).to have_link(corrective_action.document_blob.filename.to_s)
      end

      # check text area do not trigger changes by trimming whitespace and nullify blanks
      click_on "Update corrective action"

      click_link "Activity"

      expect(page).not_to have_css("p", text: "Corrective action updated:")

      click_link "Supporting information (1)"
      click_link corrective_action.decorate.supporting_information_title
      click_link "Edit corrective action"
      expect_to_have_notification_breadcrumbs

      # check error rendering and attachment details are retained
      fill_in "Year", with: "abcdefdef"
      click_on "Update corrective action"

      expect(page).to have_error_summary("Enter a real date when the corrective action came into effect")

      within_fieldset("Are there any files related to the action?") do
        expect(page).to have_checked_field("Yes")
        expect(page).to have_unchecked_field("Remove attached file")
        expect(page).to have_link(corrective_action.document_blob.filename.to_s)
        expect(page).to have_field("Attachment description", with: /#{Regexp.escape(corrective_action.document_blob.metadata['description'])}/)
      end

      within_fieldset("What action is being taken?") do
        choose new_action
      end

      fill_in "Day", with: new_date_decided.day
      fill_in "Month", with: new_date_decided.month
      fill_in "Year", with: new_date_decided.year

      within_fieldset("Which product is subject to action?") do
        choose "#{product_two.decorate.name_with_brand} (#{product_two.psd_ref})"
      end

      select new_legislation, from: "Under which legislation?"

      within_fieldset("Which business is responsible?") do
        choose business_two.trading_name
      end

      within_fieldset("In which geographic regions has this corrective action been taken?") do
        new_geographic_scopes.each do |new_geographic_scope|
          check I18n.t(new_geographic_scope, scope: %i[corrective_action attributes geographic_scopes])
        end
      end

      fill_in "Further details (optional)", with: new_details

      within_fieldset "Has the business responsible published product recall information online?" do
        choose new_has_online_recall_information ? "Yes" : "No"
        fill_in "Location of recall information", with: new_online_recall_information, visible: false
      end

      within_fieldset "Is the corrective action mandatory?" do
        choose new_measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "Yes" : "No, it’s voluntary"
      end

      within_fieldset "Are there any files related to the action?" do
        choose "Yes"
      end

      find("details > summary", text: "Replace this file").click

      # Use the correct file field name as in the original test
      attach_file "corrective_action[file][file]", Rails.root.join("spec/fixtures/files/corrective_action.txt")

      click_on "Update corrective action"

      click_on CorrectiveAction.first.decorate.supporting_information_title
      expect_to_be_on_corrective_action_summary_page
      expect_to_have_notification_breadcrumbs

      if new_action.length > CorrectiveActionDecorator::MEDIUM_TITLE_TEXT_SIZE_THRESHOLD
        expect(page).to have_css("h1.govuk-heading-m", text: new_action)
      else
        expect(page).to have_css("h1.govuk-heading-l", text: new_action)
      end

      click_link "Edit corrective action"

      within_fieldset("What action is being taken?") do
        choose new_action
      end

      within_fieldset "Are there any files related to the action?" do
        choose "Remove attached file"
      end

      click_on "Update corrective action"

      click_on CorrectiveAction.first.decorate.supporting_information_title

      expect_to_be_on_corrective_action_summary_page

      if new_action.length > CorrectiveActionDecorator::MEDIUM_TITLE_TEXT_SIZE_THRESHOLD
        expect(page).to have_css("h1.govuk-heading-m", text: new_action)
      else
        expect(page).to have_css("h1.govuk-heading-l", text: new_action)
      end

      click_link investigation.pretty_id
      click_link "Activity"

      expect(page).to have_content "Attachment removed"

      page.first("a", text: "View corrective action").click

      expect_to_be_on_corrective_action_summary_page

      click_link "Edit corrective action"

      within_fieldset("Are there any files related to the action?") do
        expect(page).to have_unchecked_field("Yes")
        expect(page).to have_checked_field("No")
        expect(page).not_to have_checked_field("Remove attached file")
      end
    end

    context "when the attached file is replaced with the same file but file description is changed" do
      it "updates the description" do
        visit "/cases/#{investigation.pretty_id}/corrective-actions/#{corrective_action.id}"

        click_link "Edit corrective action"

        within_fieldset("Are there any files related to the action?") do
          expect(page).to have_checked_field("Yes")
          expect(page).to have_unchecked_field("Remove attached file")
          expect(page).to have_link(corrective_action.document_blob.filename.to_s)
        end

        expect(page).to have_field("Attachment description", with: corrective_action.document.description)

        within_fieldset "Are there any files related to the action?" do
          choose "Yes"
        end

        find("details > summary", text: "Replace this file").click

        attach_file "corrective_action[file][file]", Rails.root.join("spec/fixtures/files/test_result.txt")
        fill_in "Attachment description", with: "Brand new attachment description"

        click_on "Update corrective action"

        click_on CorrectiveAction.first.decorate.supporting_information_title

        click_link "Edit corrective action"

        expect(page).to have_field("Attachment description", with: "Brand new attachment description")
      end
    end
  end
end
