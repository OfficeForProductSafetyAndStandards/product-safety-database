module PageExpectations
  def expect_to_be_on_the_homepage
    expect(page).to have_current_path("/")
  end

  def expect_to_be_on_cases_search_results_page(search_term:)
    expect(page).to have_current_path("/cases/search", ignore_query: true)
    expect(page).to have_h1(search_term)
  end

  # Cases pages
  def expect_to_be_on_case_page(case_id: nil)
    if case_id
      expect(page).to have_current_path("/cases/#{case_id}")
    else
      expect(page).to have_current_path(/\/cases\/[\d\-]+$/)
    end
    expect(page).to have_selector("h1", text: "Overview")
  end

  def expect_to_be_on_investigation_businesses_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/businesses")
    expect(page).to have_selector("h1", text: "Businesses")
  end

  def expect_to_be_on_investigation_add_business_type_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/businesses/type")
    expect(page).to have_selector("legend", text: "Select business type")
  end

  def expect_to_be_on_investigation_add_business_details_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/businesses/details")
    expect(page).to have_selector("legend", text: "Business details")
  end

  def expect_to_be_on_remove_business_page
    expect(page).to have_current_path(/\/cases\/#{investigation.pretty_id}\/businesses\/\d+\/remove/)
    expect(page).to have_selector("h2", text: "Remove business")
  end

  def expect_to_be_on_images_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/images")
    expect(page).to have_selector("h1", text: "Images")
  end

  def expect_to_be_on_add_image_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/new/upload")
    expect(page).to have_selector("h1", text: "Add attachment")
    expect(page).to have_link("Back", href: "/cases/#{investigation.pretty_id}/supporting-information")
  end

  def expect_to_view_supporting_information_table
    within page.first("table") do
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: email.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: "CorrespondenceEmail")
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: phone_call.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: "CorrespondencePhone call")
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: meeting.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: "CorrespondenceMeeting")
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: corrective_action.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.supporting_information_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: test_result.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.supporting_information_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.date_added)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.date_added)
    end
  end

  def expect_to_be_on_enter_image_details_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/new/metadata")
    expect(page).to have_selector("h3", text: "Image details")
    expect(page).to have_link("Back", href: "/cases/#{investigation.pretty_id}/documents/new/upload")
  end

  def expect_to_be_on_record_corrective_action_for_case_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/corrective-actions/new")
    expect(page).to have_selector("h1", text: "Record corrective action")
  end

  def expect_to_be_on_corrective_action_summary_page(is_other_action: false)
    if is_other_action
      expect(page).to have_summary_item(key: "Action",              value: new_other_action)
    else
      expect(page).to have_summary_item(key: "Action",              value: new_action)
    end

    expect(page).to have_summary_item(key: "Date of action",      value: new_date_decided.to_s(:govuk))
    expect(page).to have_summary_item(key: "Product",             value: product_two.name)
    expect(page).to have_summary_item(key: "Legislation",         value: new_legislation)
    expect(page).to have_summary_item(key: "Type of action",      value: new_measure_type.upcase_first)
    expect(page).to have_summary_item(key: "Duration of measure", value: CorrectiveAction.human_attribute_name("duration.#{new_duration}"))
    expected_geographic_scopes_text =
      new_geographic_scopes
        .map { |new_geographic_scope| I18n.t(new_geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }
        .to_sentence

    expect(page)
      .to have_summary_item(key: "Geographic scopes", value: expected_geographic_scopes_text)

    expect(page).to have_summary_item(key: "Other details", value: new_details)
  end

  def expect_to_be_on_accident_or_incident_type_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents_type/new")
    expect(page).to have_css(".govuk-fieldset__legend--m", text: "Are you recording an accident or incident?")
  end

  def expect_to_be_on_add_accident_or_incident_page(type)
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/new?type=#{type}")
    expect(page).to have_selector("h1", text: "Record an #{type.downcase}")
  end

  def expect_to_be_on_show_accident_or_incident_page
    id = UnexpectedEvent.last.id
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/#{id}")
  end

  def expect_to_be_on_confirmation_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/corrective_actions/confirmation")
    expect(page).to have_selector("h1", text: "Confirm corrective action details")
  end

  def expect_to_be_on_investigation_products_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/products")
    expect(page).to have_selector("h1", text: "Products")
  end

  def expect_to_be_on_case_products_page
    expect(page).to have_selector("h1", text: "Products")
  end

  def expect_to_be_on_remove_product_from_case_page(case_id:, product_id:)
    expect(page).to have_current_path("/cases/#{case_id}/products/#{product_id}/remove")
    expect(page).to have_selector("h2", text: "Remove product")
  end

  def expect_to_be_on_teams_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/teams")
    expect(page).to have_selector("h1", text: "Teams added to the case")
  end

  def expect_to_be_on_add_team_to_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/teams/add")
    expect(page).to have_selector("h1", text: "Add a team to the case")
  end

  def expect_to_be_on_supporting_information_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/supporting-information")
    expect(page).to have_selector("h1", text: "Supporting information")
  end

  def expect_to_be_on_add_supporting_information_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/supporting-information/new")
    expect(page).to have_selector("h1", text: "What type of information are you adding?")
  end

  def expect_to_be_on_add_attachment_to_a_case_upload_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/new/upload")
    expect(page).to have_h1("Add attachment")
  end

  def expect_to_be_on_add_attachment_to_a_case_metadata_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/new/metadata")
    expect(page).to have_h1("Add attachment")
  end

  def expect_to_be_on_case_actions_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/actions")
    expect(page).to have_selector("h1", text: "Select an action")
  end

  def expect_to_be_on_change_case_status_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/status")
    expect(page).to have_h1("Status information")
  end

  def expect_to_be_on_add_correspondence_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/correspondence/new")
    expect(page).to have_selector("h1", text: "What type of correspondence are you adding?")
  end

  def expect_to_be_on_product_attachments_page
    expect(page).to have_selector("h2", text: "Attachments")
    expect(page).to have_selector("h2", text: document.title)
    expect(page).to have_selector("p",  text: document.description)
  end

  def expect_to_be_on_edit_attachment_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/#{document.to_param}/edit")
    expect(page).to have_selector("h2", text: "Edit document details")
    expect(page).to have_link("Back", href: "/cases/#{investigation.pretty_id}/supporting-information")
  end

  def expect_to_be_on_remove_attachment_confirmation_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/#{document.id}/remove")
    expect(page).to have_selector("h2", text: "Remove attachment")
    expect(page).to have_link("Back", href: "/cases/#{investigation.pretty_id}/supporting-information")
  end

  def expect_to_be_on_case_created_page
    expect(page).to have_current_path(/\/cases\/([\d-]+)\/created/)
    expect(page).to have_selector("h1", text: "Case created")
    expect(page).to have_text(/Case ID: ([\d-]+)/)
  end

  def expect_to_be_on_new_comment_page
    expect_page_to_have_h1("Add comment")
  end

  def expect_to_be_on_compose_alert_for_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/alerts/compose")
    expect(page).to have_h1("Compose new alert")
  end

  def expect_to_be_on_about_alerts_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/alerts/about_alerts")
    expect(page).to have_h1("You cannot send an alert about a restricted case")
  end

  def expect_to_be_on_case_visiblity_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/visibility")
    expect(page).to have_h1("Legal privilege")
  end

  def expect_to_be_on_record_test_result_page
    expect_page_to_have_h1("Record test result")
    expect(page).to have_field("Which standard was the product tested against?")
  end

  def expect_to_be_on_case_activity_page(case_id: nil)
    if case_id
      expect(page).to have_current_path("/cases/#{case_id}/activity")
    else
      expect(page).to have_current_path(/\/cases\/[\d\-]+\/activity/)
    end
    expect(page).to have_selector("h1", text: "Activity")
  end

  def expect_to_be_on_test_result_page(case_id:, test_result_id: nil)
    if test_result_id
      expect(page).to have_current_path("/cases/#{case_id}/test-results/#{test_result_id}")
    else
      expect(page).to have_current_path(/\/cases\/#{case_id}\/test\-results\/[\d]+/)
    end
  end

  def expect_to_be_on_edit_test_result_page(case_id:, test_result_id: nil)
    if test_result_id
      expect(page).to have_current_path("/cases/#{case_id}/test-results/#{test_result_id}/edit")
    else
      expect(page).to have_current_path(/\/cases\/#{case_id}\/test\-results\/[\d]+\/edit/)
    end
  end

  def expect_to_be_on_corrective_action_page(case_id:, corrective_action_id: nil)
    if corrective_action_id
      expect(page).to have_current_path("/cases/#{case_id}/corrective-actions/#{corrective_action_id}")
    else
      expect(page).to have_current_path(/\/cases\/#{case_id}\/corrective-actions\/[\d]+/)
    end
  end

  def expect_to_be_on_email_page(case_id:, email_id: nil)
    if email_id
      expect(page).to have_current_path("/cases/#{case_id}/emails/#{email_id}")
    else
      expect(page).to have_current_path(/\/cases\/#{case_id}\/emails\/[\d]+/)
    end
  end

  def expect_to_be_on_edit_email_page(case_id:, email_id:)
    expect(page).to have_current_path("/cases/#{case_id}/emails/#{email_id}/edit")
    expect(page).to have_h1("Edit email")
  end

  def expect_to_be_on_phone_call_page(case_id:)
    expect(page).to have_current_path(/\/cases\/#{case_id}\/phone-calls\/[\d]+/)
  end

  # Open a case flow
  def expect_to_be_on_new_case_page
    expect(page).to have_current_path("/cases/new")
    expect(page).to have_h1("Create new")
  end

  # Add an allegation flow
  def expect_to_be_on_allegation_complainant_page
    expect(page).to have_current_path("/allegation/complainant")
    expect_page_to_have_h1("New allegation")
  end

  def expect_to_be_on_allegation_complainant_details_page
    expect(page).to have_current_path("/allegation/complainant_details")
    expect_page_to_have_h1("New allegation")
    expect(page).to have_css(".govuk-fieldset__legend--m", text: "What are their contact details?")
  end

  def expect_to_be_on_allegation_details_page
    expect(page).to have_current_path("/allegation/allegation_details")
    expect_page_to_have_h1("New allegation")
    expect(page).to have_css(".govuk-label--m", text: "What is being alleged?")
  end

  # Add an enquiry flow
  def expect_to_be_on_about_enquiry_page
    expect(page).to have_current_path("/enquiry/about_enquiry")
    expect_page_to_have_h1("New enquiry")
  end

  def expect_to_be_on_complainant_page
    expect(page).to have_current_path("/enquiry/complainant")
    expect_page_to_have_h1("New enquiry")
  end

  def expect_to_be_on_complainant_details_page
    expect(page).to have_current_path("/enquiry/complainant_details")
    expect_page_to_have_h1("New enquiry")
    expect(page).to have_css(".govuk-fieldset__legend--m", text: "What are their contact details?")
  end

  def expect_to_be_on_enquiry_details_page
    expect(page).to have_current_path("/enquiry/enquiry_details")
    expect_page_to_have_h1("New enquiry")
    expect(page).to have_css(".govuk-fieldset__legend--m", text: "What is the enquiry?")
  end

  # Trading Standards add investigation flow
  def expect_to_be_on_risk_assessment_details_page
    expect(page).to have_current_path("/ts_investigation/risk_assessments")
    expect(page).to have_selector("h1", text: "Risk assessment details")
  end

  def expect_to_be_on_reference_number_page
    expect(page).to have_current_path("/ts_investigation/reference_number")
    expect(page).to have_selector("h1", text: "Add your own reference number")
  end

  def expect_to_be_on_what_product_are_you_reporting_page
    expect(page).to have_current_path("/ts_investigation/product")
    expect(page).to have_selector("h1", text: "What product are you reporting?")
  end

  def expect_to_be_on_why_reporting_page
    expect(page).to have_current_path("/ts_investigation/why_reporting")
    expect(page).to have_selector("h1", text: "Why are you reporting this product?")
  end

  def expect_to_be_on_supply_chain_page
    expect(page).to have_current_path("/ts_investigation/which_businesses")
    expect(page).to have_selector("h1", text: "Supply chain information")
  end

  def expect_to_be_on_business_details_page(title)
    expect(page).to have_current_path("/ts_investigation/business")
    expect(page).to have_selector("h1", text: "#{title} details")
  end

  def expect_to_be_on_corrective_action_taken_page
    expect(page).to have_current_path("/ts_investigation/has_corrective_action")
    expect(page).to have_selector("h1", text: "Has any corrective action been agreed or taken?")
  end

  def expect_to_be_on_record_corrective_action_page
    expect(page).to have_current_path("/ts_investigation/corrective_action")
    expect(page).to have_selector("h1", text: "Record corrective action")
  end

  def expect_to_be_on_other_information_page
    expect(page).to have_current_path("/ts_investigation/other_information")
    expect(page).to have_selector("h1", text: "Other information and files")
  end

  def expect_to_be_on_test_result_details_page
    expect(page).to have_current_path("/ts_investigation/test_results")
    expect(page).to have_selector("h1", text: "Test result details")
  end

  def expect_to_be_on_product_image_page
    expect(page).to have_current_path("/ts_investigation/product_images")
    expect(page).to have_selector("h1", text: "Upload a product image")
  end

  # Product pages
  def expect_to_be_on_remove_attachment_from_product_confirmation_page
    expect(page).to have_current_path("/products/#{product.id}/documents/#{document.id}/remove")
    expect(page).to have_selector("h2", text: "Remove attachment")
    expect(page).to have_link("Back", href: "/products/#{product.id}#attachments")
  end

  def expect_to_be_on_product_page(product_id:, product_name:)
    expect(page).to have_current_path("/products/#{product_id}")
    expect(page).to have_selector("h1", text: product_name)
  end

  def expect_to_be_on_edit_product_page(product_id: nil, product_name: nil)
    expect(page).to have_current_path("/products/#{product_id}/edit")
    expect(page).to have_selector("h1", text: product_name)
  end

  def expect_to_be_on_add_attachment_to_a_product_upload_page(product_id:)
    expect(page).to have_current_path("/products/#{product_id}/documents/new/upload")
    expect(page).to have_h1("Add attachment")
  end

  def expect_to_be_on_add_attachment_to_a_product_metadata_page(product_id:)
    expect(page).to have_current_path("/products/#{product_id}/documents/new/metadata")
    expect(page).to have_h1("Add attachment")
  end

  # Shared pages across different flows
  def expect_to_be_on_coronavirus_page(path)
    expect(page).to have_current_path(path)
    expect(page).to have_selector("h1", text: "Is this case related to the coronavirus outbreak?")
  end

  # Login and account management pages
  def expect_to_be_on_secondary_authentication_page
    expect(page).to have_current_path(/\/two-factor/)
    expect(page).to have_h1("Check your phone")
  end

  def expect_to_be_on_resend_secondary_authentication_page
    expect(page).to have_current_path("/text-not-received")
    expect(page).to have_h1("Resend security code")
  end

  def expect_to_be_on_complete_registration_page
    expect(page).to have_current_path(/\/complete-registration?.+$/)
    expect(page).to have_h1("Create an account")
    expect(page).to have_field("username", type: "email", with: invited_user.email, disabled: true)
  end

  def expect_to_be_on_signed_in_as_another_user_page
    expect(page).to have_h1("You are already signed in to the Product safety database")
  end

  def expect_to_be_on_declaration_page
    expect(page).to have_current_path(/^\/declaration$/)
    expect(page).to have_title("Declaration - Product safety database - GOV.UK")
  end

  def expect_to_be_on_reset_password_page
    expect(page).to have_current_path("/password/new")
  end

  def expect_to_be_on_edit_user_password_page
    expect(page).to have_current_path("/password/edit", ignore_query: true)
  end

  def expect_to_be_on_check_your_email_page
    expect(page).to have_css("h1", text: "Check your email")
  end

  def expect_to_be_on_password_changed_page
    expect(page).to have_current_path("/password-changed")
    expect(page).to have_css("h1", text: "You have changed your password successfully")
  end

  def expect_to_be_on_your_account_page
    expect(page).to have_current_path("/account")
    expect(page).to have_selector("h1", text: "Your account")
  end

  def expect_to_be_on_change_name_page
    expect(page).to have_current_path("/account/name")
    expect(page).to have_selector("h1", text: "Change your name")
  end

  def expect_to_be_on_team_page(team)
    expect(page).to have_css("h1", text: team.name)
  end

  def expect_to_be_on_invite_a_team_member_page
    expect(page).to have_css("h1", text: "Invite a team member")
  end

  def expect_to_be_on_edit_case_permissions_page(case_id:)
    collaboration = Investigation.find_by(pretty_id: case_id).collaboration_accesses.find_by!(collaborator: team)
    expect(page).to have_current_path("/cases/#{case_id}/teams/#{collaboration.id}/edit")
    expect(page).to have_selector("h1", text: team.name)
  end

  # Businesses
  def expect_to_be_on_business_page(business_id:, business_name:)
    expect(page).to have_current_path("/businesses/#{business_id}")
    expect(page).to have_selector("h1", text: business_name)
  end

  def expect_to_be_on_edit_business_page(business_id:, business_name:)
    expect(page).to have_current_path("/businesses/#{business_id}/edit")
    expect(page).to have_title("Edit business - Product safety database - GOV.UK")
    expect(page).to have_selector("h1", text: business_name)
  end

  def expect_to_be_on_add_business_to_location_page(business_id:)
    expect(page).to have_current_path("/businesses/#{business_id}/locations/new")
    expect(page).to have_h1("Add location")
  end

  def expect_to_be_on_edit_location_for_a_business_page(business_id:, location_id: nil)
    if location_id
      expect(page).to have_current_path("/businesses/#{business_id}/locations/#{location_id}/edit")
    else
      expect(page).to have_current_path(/\/businesses\/#{business_id}\/locations\/\d+\/edit/)
    end
    expect(page).to have_h1("Edit location")
  end

  def expect_to_be_on_remove_location_for_a_business_page(business_id:, location_id: nil)
    expect(page).to have_current_path("/businesses/#{business_id}/locations/#{location_id}/remove")
    expect(page).to have_h1("Remove location")
  end

  def expect_to_be_on_add_attachment_to_a_business_upload_page(business_id:)
    expect(page).to have_current_path("/businesses/#{business_id}/documents/new/upload")
    expect(page).to have_h1("Add attachment")
  end

  def expect_to_be_on_add_attachment_to_a_business_metadata_page(business_id:)
    expect(page).to have_current_path("/businesses/#{business_id}/documents/new/metadata")
    expect(page).to have_h1("Add attachment")
  end

  def expect_to_be_on_add_contact_to_a_business_page(business_id:)
    expect(page).to have_current_path("/businesses/#{business_id}/contacts/new")
    expect(page).to have_h1("Add contact")
  end

  def expect_to_be_on_edit_business_contact_page(business_id:, contact_id:)
    expect(page).to have_current_path("/businesses/#{business_id}/contacts/#{contact_id}/edit")
    expect(page).to have_h1("Edit contact")
  end

  def expect_to_be_on_remove_contact_for_a_business_page(business_id:, contact_id:)
    expect(page).to have_current_path("/businesses/#{business_id}/contacts/#{contact_id}/remove")
    expect(page).to have_h1("Remove contact")
  end

  def expect_teams_tables_to_contain(expected_teams)
    teams_table = page.find(:table, "Teams added to the case")

    within(teams_table) do
      expected_teams.each do |expected_team|
        row_heading = page.find("th", text: expected_team[:team_name])
        expect(row_heading).to have_sibling("td", text: expected_team[:permission_level])

        if expected_team[:creator]
          expect(row_heading).to have_text("Case creator")
        end
      end
    end
  end

  def expect_teams_tables_not_to_contain(teams)
    teams_table = page.find(:table, "Teams added to the case")

    within(teams_table) do
      teams.each do |expected_team|
        elems = page.all("th", text: expected_team[:team_name])
        expect(elems).to be_empty, "#{expected_team[:team_name]} should not be visible"
      end
    end
  end

  def expect_to_be_on_access_denied_page
    expect(page).to have_css("h1", text: "Access denied")
  end

  def expect_to_be_on_record_phone_call_page
    expect_page_to_have_h1("Record phone call")
    expect(page).to have_selector("legend", text: "Who was the call with?")
  end

  def expect_to_be_on_record_phone_call_details_page
    expect_page_to_have_h1("Record phone call")
    expect(page).to have_selector("legend", text: "Details")
  end

  def expect_to_be_on_record_email_page
    expect_page_to_have_h1("Record email")
    expect(page).to have_selector("legend", text: "Email details")
  end

  def expect_to_be_on_record_email_details_page
    expect_page_to_have_h1("Record email")
    expect(page).to have_selector("legend", text: "Email content")
  end

  def expect_to_be_on_confirm_email_details_page
    expect_page_to_have_h1("Confirm email details")
  end

  def expect_to_be_on_set_risk_level_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/edit-risk-level")
    expect_page_to_have_h1("Set case risk level")
  end

  def expect_to_be_on_change_risk_level_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/edit-risk-level")
    expect_page_to_have_h1("Change case risk level")
  end

  def expect_to_be_on_add_risk_assessment_for_a_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/risk-assessments/new")
    expect_page_to_have_h1("Add risk assessment")
  end

  def expect_to_be_on_risk_assessement_for_a_case_page(case_id:, risk_assessment_id: nil)
    if risk_assessment_id
      expect(page).to have_current_path("/cases/#{case_id}/risk-assessments/#{risk_assessment_id}")
    else
      expect(page).to have_current_path(/\/cases\/#{case_id}\/risk\-assessments\/\d+/)
    end
  end

  def expect_to_be_on_edit_risk_assessement_page(case_id:, risk_assessment_id:)
    expect(page).to have_current_path("/cases/#{case_id}/risk-assessments/#{risk_assessment_id}/edit")
  end

  def expect_to_be_on_update_case_risk_level_from_risk_assessment_page(case_id:, risk_assessment_id: nil)
    if risk_assessment_id
      expect(page).to have_current_path("/cases/#{case_id}/risk-assessments/#{risk_assessment_id}/update-case-risk-level")
    else
      expect(page).to have_current_path(/\/cases\/#{case_id}\/risk\-assessments\/\d+\/update\-case\-risk\-level/)
    end
    expect_page_to_have_h1("Case risk level")
  end

  def expect_to_be_on_case_summary_edit_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/summary/edit")
  end
end
