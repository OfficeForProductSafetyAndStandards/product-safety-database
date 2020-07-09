require "rails_helper"

RSpec.feature "Edit corrective action", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include_context "with corrective action setup for updates"

  before do
    investigation.businesses << business_one << business_two
    sign_in user
  end

  context "when a single product is chosen" do
    it "provides a mean to edit a corrective action" do
      visit "/cases/#{investigation.pretty_id}/corrective-actions/#{corrective_action.id}"

      click_link "Edit corrective action"

      fill_in "Summary",                    with: new_summary
      fill_in "Day",                        with: new_date_decided.day
      fill_in "Month",                      with: new_date_decided.month
      fill_in "Year",                       with: new_date_decided.year
      select product_two.name,              from: "Product"
      select new_legislation,               from: "Under which legislation?"
      select business_two.trading_name,     from: "Business"
      select new_geographic_scope,          from: "What is the geographic scope of the action?"
      fill_in "Further details (optional)", with: new_details
      choose new_measure_type == CorrectiveAction::MEASURE_TYPES[0] ? "Yes" : "No, it’s voluntary"
      choose CorrectiveAction.human_attribute_name("duration.#{new_duration}")

      click_on "Update corrective action"

      expect(page).to have_summary_item(key: "Date of action",      value: new_date_decided.to_s(:govuk))
      expect(page).to have_summary_item(key: "Product",             value: product_two.name)
      expect(page).to have_summary_item(key: "Legislation",         value: new_legislation)
      expect(page).to have_summary_item(key: "Type of action",      value: new_measure_type.upcase_first)
      expect(page).to have_summary_item(key: "Duration of measure", value: CorrectiveAction.human_attribute_name("duration.#{new_duration}"))
      expect(page).to have_summary_item(key: "Scope",               value: new_geographic_scope)
      expect(page).to have_summary_item(key: "Other details",       value: new_details)
    end
  end
end
