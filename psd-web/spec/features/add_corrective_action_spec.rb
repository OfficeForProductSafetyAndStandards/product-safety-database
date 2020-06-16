require "rails_helper"

RSpec.feature "Adding a correcting action to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let(:investigation) { create(:allegation, products: [product], owner: user, creator: user) }

  let(:summary) { Faker::Lorem.sentence }
  let(:date) { Date.parse("2020-05-01") }
  let(:legislation) { "General Product Safety Regulations 2005" }
  let(:details) { "Urgent action following consumer reports" }
  let(:file) { Rails.root + "test/fixtures/files/old_risk_assessment.txt" }
  let(:file_description) { Faker::Lorem.paragraph }
  let(:measure_type) { "Mandatory" }
  let(:duration) { "Permanent" }
  let(:geographic_scope) { "National" }

  before { sign_in(user) }

  scenario "Adding a corrective action (with validation errors)" do
    visit "/cases/#{investigation.pretty_id}/supporting-information"

    click_link "Add supporting information"

    choose "Record corrective action"

    click_button "Continue"

    expect_to_be_on_record_corrective_action_for_case_page
    expect(page).not_to have_error_messages

    fill_and_submit_form

    expect_to_be_on_confirmation_page
    expect(page).not_to have_error_messages

    expect_confirmation_page_to_show_entered_data

    click_link "Edit details"

    expect_form_to_show_input_data

    click_button "Continue"

    expect_confirmation_page_to_show_entered_data

    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).not_to have_error_messages

    click_link "Supporting information (1)"

    expect_case_supporting_information_page_to_show_file

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect_case_activity_page_to_show_entered_data

    click_link "View corrective action"

    expect_to_be_on_corrective_action_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Date of action", value: "1 May 2020")
    expect(page).to have_summary_item(key: "Product", value: "MyBrand Washing Machine")
    expect(page).to have_summary_item(key: "Legislation", value: "General Product Safety Regulations 2005")
    expect(page).to have_summary_item(key: "Type of action", value: "Mandatory")
    expect(page).to have_summary_item(key: "Duration of measure", value: "Permanent")
    expect(page).to have_summary_item(key: "Scope", value: "National")
    expect(page).to have_summary_item(key: "Other details", value: "Urgent action following consumer reports")

    expect(page).to have_link("old_risk_assessment.txt")
  end

  def expect_confirmation_page_to_show_entered_data
    expect(page).to have_summary_item(key: "Summary", value: summary)
    expect(page).to have_summary_item(key: "Date of action", value: "1 May 2020")
    expect(page).to have_summary_item(key: "Legislation", value: legislation)
    expect(page).to have_summary_item(key: "Details", value: details)
    expect(page).to have_summary_item(key: "Attachment", value: File.basename(file))
    expect(page).to have_summary_item(key: "Attachment description", value: file_description)
    expect(page).to have_summary_item(key: "Type of measure", value: CorrectiveAction.human_attribute_name("measure_type.#{measure_type}"))
    expect(page).to have_summary_item(key: "Duration of action", value: CorrectiveAction.human_attribute_name("duration.#{duration}"))
    expect(page).to have_summary_item(key: "Geographic scope", value: geographic_scope)
  end

  def expect_form_to_show_input_data
    expect(page).to have_field("Summary", with: summary)
    expect(page).to have_field("Day", with: date.day)
    expect(page).to have_field("Month", with: date.month)
    expect(page).to have_field("Year", with: date.year)
    expect(page).to have_field("Under which legislation?", with: legislation)

    within_fieldset "Is the corrective action mandatory?" do
      expect(page).to have_checked_field("Yes")
    end

    within_fieldset "How long will the corrective action be in place?" do
      expect(page).to have_checked_field(duration)
    end

    expect(page).to have_field("What is the geographic scope of the action?", with: geographic_scope)
    expect(page).to have_selector("#conditional-corrective_action_related_file_yes a", text: File.basename(file))
    expect(page).to have_field("Attachment description", with: /#{Regexp.escape(file_description)}/)
  end

  def expect_case_activity_page_to_show_entered_data
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: summary).find(:xpath, "..")
    expect(item).to have_text("Legislation: #{legislation}")
    expect(item).to have_text("Date came into effect: #{date.strftime('%d/%m/%Y')}")
    expect(item).to have_text("Type of measure: #{CorrectiveAction.human_attribute_name("measure_type.#{measure_type}")}")
    expect(item).to have_text("Duration of action: #{CorrectiveAction.human_attribute_name("duration.#{duration}")}")
    expect(item).to have_text("Geographic scope: #{geographic_scope}")
    expect(item).to have_text("Attached: #{File.basename(file)}")
    expect(item).to have_text("Geographic scope: #{geographic_scope}")
    expect(item).to have_text(details)
  end

  def expect_case_supporting_information_page_to_show_file
    expect(page).to have_css("h1", text: "Supporting information")
  end

  def fill_and_submit_form
    fill_in "Summary", with: summary
    fill_in "Day",     with: date.day   if date
    fill_in "Month",   with: date.month if date
    fill_in "Year",    with: date.year  if date

    select legislation, from: "Under which legislation?"

    fill_in "Further details (optional)", with: details

    within_fieldset "Are there any files related to the action?" do
      choose "Yes"
    end

    attach_file "Upload a file", file

    fill_in "Attachment description", with: file_description

    within_fieldset "Is the corrective action mandatory?" do
      choose "Yes"
    end

    within_fieldset "How long will the corrective action be in place?" do
      choose duration
    end

    select geographic_scope, from: "What is the geographic scope of the action?"

    fill_in "Further details (optional)", with: "Urgent action following consumer reports"
    click_button "Continue"
  end
end
