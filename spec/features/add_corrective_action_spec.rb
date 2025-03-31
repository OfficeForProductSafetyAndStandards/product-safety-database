require "rails_helper"

RSpec.feature "Adding a correcting action to a case", :with_stubbed_antivirus, :with_stubbed_mailer, :with_test_queue_adapter, type: :feature do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  context "when the viewing user only has read only access" do
    scenario "cannot add supporting information" do
      sign_in(read_only_user)
      visit "/cases/#{notification.pretty_id}"
      expect(page).not_to have_link("Add a corrective action")
    end

    scenario "cannot view the new corrective action form" do
      sign_in(read_only_user)
      visit "/cases/#{notification.pretty_id}/corrective-actions/new"
      expect(page).to have_http_status(:forbidden)
    end
  end

  context "with no product added to the case" do
    let(:products) { [] }

    scenario "shows errors" do
      sign_in(user)

      visit "/cases/#{notification.pretty_id}/corrective-actions/new"

      expect(page).to have_text("There are no products associated with this notification.")

      click_button "Add corrective action"

      expect(page).to have_error_messages
      expect(page).to have_error_summary "Select the product the corrective action relates to"
    end
  end

  scenario "Adding a corrective action (with validation errors)" do
    sign_in(user)
    visit "/cases/#{notification.pretty_id}"
    click_link "Add a corrective action"

    expect(page).to have_current_path("/cases/#{notification.pretty_id}/corrective-actions/new")
    expect(page).to have_selector("h1", text: "Record a corrective action")
    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    click_button "Add corrective action"
    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select type of corrective action"
    expect(errors_list[1].text).to eq "Enter the date the corrective action came into effect"
    expect(errors_list[2].text).to eq "Select the legislation relevant to the corrective action"
    expect(errors_list[3].text).to eq "You must state whether the action is mandatory or voluntary"
    expect(errors_list[4].text).to eq "Select the geographic scope of the action"
    expect(errors_list[5].text).to eq "Select whether you want to upload a related file"

    enter_non_numeric_date_and_expect_correct_error_message

    # Test file attachments are retained on validation errors
    within_fieldset "Are there any files related to the action?" do
      choose "Yes"
    end

    attach_file "corrective_action[file][file]", file
    fill_in "Attachment description", with: file_description
    click_button "Add corrective action"

    expect(page).to have_text("Currently selected file: #{File.basename(file)}")
    expect(page).to have_text("Replace this file")
    expect(page).to have_field("Attachment description", with: file_description)
    expect_to_have_notification_breadcrumbs

    fill_and_submit_form

    expect_to_be_on_supporting_information_page(case_id: notification.pretty_id)
    expect_to_have_notification_breadcrumbs

    click_link CorrectiveAction.first.decorate.supporting_information_title

    expect(page).to have_summary_item(key: "Event date", value: "1 May 2020")
    expect(page).to have_summary_item(key: "Product",             value: "MyBrand Washing Machine (#{product.psd_ref})")
    expect(page).to have_summary_item(key: "Legislation",         value: "General Product Safety Regulations 2005")
    expect(page).to have_summary_item(key: "Recall information",  value: "#{online_recall_information} (opens in new tab)")
    expect(page).to have_summary_item(key: "Type of action",      value: "Mandatory")
    expect(page).to have_summary_item(key: "Geographic scopes",   value: geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }.to_sentence)
    expect(page).to have_summary_item(key: "Other details",       value: "Urgent action following consumer reports")

    expect(page).to have_link("old_risk_assessment.txt")

    click_link notification.pretty_id
    click_link "Supporting information (1)"

    expect_case_supporting_information_page_to_show_file
    expect_to_have_notification_breadcrumbs

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)

    expect_case_activity_page_to_show_entered_data

    click_link "View corrective action"

    expect_to_be_on_corrective_action_page(case_id: notification.pretty_id)
    expect_to_have_notification_breadcrumbs

    expect(page).to have_summary_item(key: "Event date", value: "1 May 2020")
    expect(page).to have_summary_item(key: "Product",             value: "MyBrand Washing Machine (#{product.psd_ref})")
    expect(page).to have_summary_item(key: "Legislation",         value: "General Product Safety Regulations 2005")
    expect(page).to have_summary_item(key: "Type of action",      value: "Mandatory")
    expect(page).to have_summary_item(key: "Geographic scopes",   value: geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }.to_sentence)
    expect(page).to have_summary_item(key: "Other details",       value: "Urgent action following consumer reports")

    expect(page).to have_link("old_risk_assessment.txt")
  end

  scenario "Adding a corrective action with file upload" do
    sign_in(user)
    visit "/cases/#{notification.pretty_id}"
    click_link "Add a corrective action"

    expect(page).to have_current_path("/cases/#{notification.pretty_id}/corrective-actions/new")
    expect(page).to have_selector("h1", text: "Record a corrective action")
    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    # Add a file attachment
    within_fieldset "Are there any files related to the action?" do
      choose "Yes"
    end

    file_path = Rails.root.join("spec/fixtures/files/test_result.txt")
    attach_file "corrective_action[file][file]", file_path
    fill_in "Attachment description", with: "Test result file"

    # Use the existing method to fill and submit the form
    fill_and_submit_form

    # Verify the corrective action was created successfully
    expect_to_be_on_supporting_information_page(case_id: notification.pretty_id)
    expect_to_have_notification_breadcrumbs

    # Check that the file is listed
    click_link CorrectiveAction.first.decorate.supporting_information_title
    expect(page).to have_link("test_result.txt")
  end

  def expect_confirmation_page_to_show_entered_data
    expect(page).to have_summary_item(key: "Action", value: CorrectiveAction.actions[action])
    expect(page).to have_summary_item(key: "Event date", value: "1 May 2020")
    expect(page).to have_summary_item(key: "Legislation", value: legislation)
    expect(page).to have_summary_item(key: "Details", value: details)
    expect(page).to have_summary_item(key: "Attachment", value: File.basename(file))
    expect(page).to have_summary_item(key: "Attachment description", value: file_description)
    expect(page).to have_summary_item(key: "Type of measure", value: CorrectiveAction.human_attribute_name("measure_type.#{measure_type}"))
    expect(page).to have_summary_item(key: "Geographic scopes", value: geographic_scopes.to_sentence)
  end

  def expect_form_to_show_input_data
    within_fieldset "What action is being taken?" do
      expect(page).to have_checked_field(action)
    end

    expect(page).to have_field("Day", with: date_decided.day)
    expect(page).to have_field("Month", with: date_decided.month)
    expect(page).to have_field("Year", with: date_decided.year)
    expect(page).to have_field("Under which legislation?", with: legislation)

    within_fieldset "Is the corrective action mandatory?" do
      expect(page).to have_checked_field("Yes")
    end

    within_fieldset "What is the geographic scope of the action?" do
      geographic_scopes_keys.each do |geographic_scope|
        expect(page).to have_checked_field(I18n.t(geographic_scope, scope: %i[investigations corrective_actions confirmation]))
      end
    end

    expect(page).to have_selector("#conditional-related_file a", text: File.basename(file))
    expect(page).to have_field("Attachment description", with: /#{Regexp.escape(file_description)}/)
  end

  def expect_case_activity_page_to_show_entered_data
    expect(page).to have_selector("h1", text: "Activity")
    corrective_action_title = "#{CorrectiveAction::TRUNCATED_ACTION_MAP[action_key.to_sym]}: #{product.name}"
    item = page.find("h3", text: corrective_action_title).find(:xpath, "..")
    expect(item).to have_text("Legislation: #{legislation}")
    expect(item).to have_text("Date came into effect: #{date_decided.to_formatted_s(:govuk)}")
    expect(item).to have_text("Type of measure: #{CorrectiveAction.human_attribute_name("measure_type.#{measure_type}")}")
    expect(item).to have_text("Geographic scopes: #{geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }.to_sentence}")
    expect(item).to have_text("Attached: #{File.basename(file)}")
    expect(item).to have_text(details)
    expect(item).to have_link("View business details", href: business_url(business))
  end

  def expect_case_supporting_information_page_to_show_file
    expect(page).to have_css("h1", text: "Supporting information")
  end

  def fill_and_submit_form
    choose action
    fill_in "Day",     with: date_decided.day   if date_decided
    fill_in "Month",   with: date_decided.month if date_decided
    fill_in "Year",    with: date_decided.year  if date_decided

    select legislation, from: "Under which legislation?"

    within_fieldset "Which business is responsible?" do
      choose business.trading_name
    end

    within_fieldset "Has the business responsible published product recall information online?" do
      choose "Yes"
      fill_in "Location of recall information", with: online_recall_information, visible: false
    end

    fill_in "Further details (optional)", with: details

    within_fieldset "Is the corrective action mandatory?" do
      choose "Yes"
    end

    within_fieldset "In which geographic regions has this corrective action been taken?" do
      geographic_scopes.each do |geographic_scope|
        check I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes])
      end
    end

    fill_in "Further details (optional)", with: "Urgent action following consumer reports"
    click_button "Add corrective action"
  end

  def enter_non_numeric_date_and_expect_correct_error_message
    fill_in "Day",     with: "abc" if date_decided
    fill_in "Month",   with: "xyz" if date_decided
    fill_in "Year",    with: "xxxxxx" if date_decided

    click_button "Add corrective action"

    expect(page).to have_error_summary("Enter the date the corrective action came into effect")
  end
end
