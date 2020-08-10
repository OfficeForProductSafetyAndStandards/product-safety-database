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

      expect(page).to have_field("Summary", with: corrective_action.summary)
      expect(page).to have_field("Day",     with: corrective_action.date_decided.day)
      expect(page).to have_field("Month",   with: corrective_action.date_decided.month)
      expect(page).to have_field("Year",    with: corrective_action.date_decided.year)
      expect(page).to have_select("Product", selected: corrective_action.product.name)
      expect(page).to have_select("Under which legislation?", selected: corrective_action.legislation)
      expect(page).to have_select("Business", selected: corrective_action.business.trading_name)
      expect(page).to have_select("What is the geographic scope of the action?", selected: corrective_action.geographic_scope)
      expect(page).to have_field("Further details (optional)", with: "\r\n#{corrective_action.details}", type: "textarea")
      measure_type = corrective_action.measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "Yes" : "No, it’s voluntary"
      expect(page).to have_checked_field(measure_type)
      expect(page).to have_checked_field(CorrectiveAction.human_attribute_name("duration.#{corrective_action.duration}"))
      document = corrective_action.documents_blobs.first
      expect(page).to have_link(document.filename.to_s)

      fill_in "Summary",                    with: new_summary
      fill_in "Day",                        with: new_date_decided.day
      fill_in "Month",                      with: new_date_decided.month
      fill_in "Year",                       with: new_date_decided.year
      select product_two.name,              from: "Product"
      select new_legislation,               from: "Under which legislation?"
      select business_two.trading_name,     from: "Business"
      select new_geographic_scope,          from: "What is the geographic scope of the action?"
      fill_in "Further details (optional)", with: new_details
      choose new_measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "corrective_action_measure_type_mandatory" : "corrective_action_measure_type_voluntary"
      choose CorrectiveAction.human_attribute_name("duration.#{new_duration}")

      choose "corrective_action_related_file_true"
      find("details > summary", text: "Replace this file").click

      attach_file "Upload a file", Rails.root + "spec/fixtures/files/corrective_action.txt"
      fill_in "Attachment description", with: "New test result"

      click_on "Update corrective action"

      expect_to_be_on_corrective_action_summary_page

      click_link "Back to #{investigation.decorate.pretty_description.downcase}"
      click_link "Activity"

      click_link "View corrective action"

      expect_to_be_on_corrective_action_summary_page
    end
  end
end
