require "rails_helper"

RSpec.feature "Edit corrective action", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_antivirus do
  include_context "with corrective action setup for updates"

  before do
    investigation.businesses << business_one << business_two
    sign_in user
  end

  context "when a single product is chosen" do
    it "provides a mean to edit a corrective action" do
      visit "/cases/#{investigation.pretty_id}/corrective-actions/#{corrective_action.id}"

      click_link "Edit corrective action"

      within_fieldset("What action is being taken?") { expect(page).to have_checked_field(CorrectiveAction.actions[corrective_action.action]) }
      expect(page).to have_field("Day",     with: corrective_action.date_decided.day)
      expect(page).to have_field("Month",   with: corrective_action.date_decided.month)
      expect(page).to have_field("Year",    with: corrective_action.date_decided.year)
      expect(page).to have_select("Product", selected: corrective_action.product.name)
      expect(page).to have_select("Under which legislation?", selected: corrective_action.legislation)
      expect(page).to have_select("Business", selected: corrective_action.business.trading_name)
      corrective_action.geographic_scopes.each do |geographic_scope|
        expect(page).to have_checked_field(I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]))
      end
      expect(page).to have_field("Further details (optional)", with: "\r\n#{corrective_action.details}", type: "textarea")
      measure_type = corrective_action.measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "Yes" : "No, it’s voluntary"
      expect(page).to have_checked_field(measure_type)
      expect(page).to have_checked_field(CorrectiveAction.human_attribute_name("duration.#{corrective_action.duration}"))
      document = corrective_action.documents_blobs.first
      expect(page).to have_link(document.filename.to_s)

      within_fieldset("What action is being taken?") do
        choose "Other"
        fill_in "corrective_action[other_action]", with: Faker::Hipster.paragraph(sentence_count: 3)
      end

      fill_in "Day",                        with: new_date_decided.day
      fill_in "Month",                      with: new_date_decided.month
      fill_in "Year",                       with: new_date_decided.year
      select product_two.name,              from: "Product"
      select new_legislation,               from: "Under which legislation?"
      select business_two.trading_name,     from: "Business"
      within_fieldset("What is the geographic scope of the action?") do
        new_geographic_scopes.each do |new_geographic_scope|
          check I18n.t(new_geographic_scope, scope: %i[corrective_action attributes geographic_scopes])
        end
      end

      fill_in "Further details (optional)", with: new_details
      within_fieldset "Is the corrective action mandatory?" do
        choose new_measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "Yes" : "No, it’s voluntary"
      end
      choose CorrectiveAction.human_attribute_name("duration.#{new_duration}")

      within_fieldset "Are there any files related to the action?" do
        choose "Yes"
      end

      find("details > summary", text: "Replace this file").click

      attach_file "Upload a file", Rails.root + "spec/fixtures/files/corrective_action.txt"
      fill_in "Attachment description", with: "New test result"

      click_on "Update corrective action"

      expect_to_be_on_corrective_action_summary_page

      expect(page).to have_css("h1.govuk-heading-m", text: corrective_action.other_action)

      click_link "Edit corrective action"

      new_action = (CorrectiveAction.actions.values - %w[Other]).sample
      within_fieldset("What action is being taken?") do
        choose new_action
      end

      click_on "Update corrective action"

      expect_to_be_on_corrective_action_summary_page

      if new_action.length > CorrectiveActionDecorator::MEDIUM_TITLE_TEXT_SIZE_THRESHOLD
        expect(page).to have_css("h1.govuk-heading-m", text: new_action)
      else
        expect(page).to have_css("h1.govuk-heading-l", text: new_action)
      end

      click_link "Back to #{investigation.decorate.pretty_description.downcase}"
      click_link "Activity"

      page.first("a", text: "View corrective action").click

      expect_to_be_on_corrective_action_summary_page
    end
  end
end
