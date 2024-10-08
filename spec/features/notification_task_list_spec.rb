require "rails_helper"

RSpec.feature "Notification task list", :with_opensearch, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:user_one) { create(:user, :opss_user, :activated, has_viewed_introduction: true) }
  let(:user_two) { create(:user, :opss_user, :activated, has_viewed_introduction: true) }
  let(:notif_one) { create_new_notification(user) }
  let(:notif_two) { create_new_notification(user_one) }
  let(:notif_three) { create_new_notification(user_one) }
  let(:notif_four) { create_new_notification(user_one, team: user_two) }
  let(:existing_product) { create(:product) }
  let(:new_product_attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end
  let(:image_file) { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:text_file) { Rails.root.join "test/fixtures/files/attachment_filename.txt" }

  before do
    existing_product
    user_one.team = user.team
    user_one.save!
  end

  scenario "Viewing notifications page without NTL role" do
    sign_in(user_one)
    visit "/notifications/your-notifications"
    expect_to_be_on_cases_page
    visit "/notifications/team-notifications"
    expect_to_be_on_team_cases_page
  end

  scenario "Viewing user notifications and team notifications through filters" do
    notif_one
    notif_two
    notif_three
    notif_four
    Investigation::Notification.reindex

    sign_in(user)
    visit "/notifications"
    expect(page).to have_text(notif_one.user_title)

    visit "/notifications/your-notifications"
    expect(page).to have_text(notif_one.user_title)

    visit "/notifications/team-notifications"
    expect(page).to have_text(notif_one.user_title)
    expect(page).to have_text(notif_two.user_title)
    expect(page).to have_text(notif_three.user_title)

    click_link notif_one.user_title
    expect(page).to have_current_path("/notifications/#{notif_one.pretty_id}")

    visit "/notifications/assigned-notifications"
    expect(page).to have_text(notif_four.user_title)
  end

  scenario "Creating an empty notification" do
    sign_in(user)
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Not yet started")
  end

  scenario "Creating a notification from an existing product" do
    sign_in(user)
    visit "/notifications/create/from-product/#{existing_product.id}"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/search_for_or_add_a_product/)
    expect(page).to have_content("Search for or add a product")

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"

    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Completed")
  end

  scenario "Creating a draft notification with two products and removing one" do
    sign_in(user)
    visit "/notifications/create/from-product/#{existing_product.id}"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/search_for_or_add_a_product/)
    expect(page).to have_content("Search for or add a product")

    within_fieldset "Do you need to add another product?" do
      choose "Yes"
    end

    click_button "Continue"
    add_a_product

    all("a", text: "Remove")[0].click

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/remove-product\/\d{1}/)
    click_button "Remove product"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/search_for_or_add_a_product/)

    all("a", text: "Remove")[0].click

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/remove-product\/\d{1}/)
    click_button "Remove product"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/search_for_or_add_a_product/)
  end

  scenario "Adding a new product to an existing notification" do
    sign_in(user)
    visit "/notifications/create"

    click_link "Search for or add a product"
    add_a_product

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"

    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Completed")
  end

  scenario "Creating a notification with the normal flow" do
    sign_in(user)
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Not yet started")

    click_link "Search for or add a product"
    click_button "Select", match: :first

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"

    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Completed")
    expect(page).to have_content("You have completed 1 of 6 sections.")

    click_link "Add notification details"

    add_notification_details_one
    add_notification_details_two
    add_notification_details_three

    expect(page).to have_selector(:id, "task-list-1-0-status", text: "Completed")
    expect(page).to have_selector(:id, "task-list-1-1-status", text: "Completed")
    expect(page).to have_selector(:id, "task-list-1-2-status", text: "Completed")
    expect(page).to have_content("You have completed 2 of 6 sections.")

    create_business

    within_fieldset "Do you need to add another business?" do
      choose "No"
    end
    click_button "Continue"

    expect(page).to have_selector(:id, "task-list-2-0-status", text: "Completed")
    expect(page).to have_content("You have completed 3 of 6 sections.")

    # Ensure that all of section 4 and the first task of section are enabled once section 3 is completed
    expect(page).to have_selector(:id, "task-list-3-0-status", text: "Not yet started")
    expect(page).to have_selector(:id, "task-list-3-1-status", text: "Not yet started")
    expect(page).to have_selector(:id, "task-list-3-2-status", text: "Not yet started")
    expect(page).to have_selector(:id, "task-list-3-3-status", text: "Not yet started")
    expect(page).to have_selector(:id, "task-list-3-4-status", text: "Not yet started")
    expect(page).to have_selector(:id, "task-list-3-5-status", text: "Not yet started")
    expect(page).to have_selector(:id, "task-list-4-0-status", text: "Not yet started")

    add_product_identification_details

    click_link "Add test reports"
    choose "Yes"
    click_button "Save and continue"

    add_test_report

    expect(page).to have_selector(:id, "task-list-3-0-status", text: "Completed")

    click_link "Add supporting images"

    add_supporting_images

    expect(page).to have_selector(:id, "task-list-3-1-status", text: "Completed")

    click_link "Add supporting documents"

    add_supporting_documents

    expect(page).to have_selector(:id, "task-list-3-2-status", text: "Completed")

    click_link "Add risk assessments"
    click_link "Add legacy risk assessment"

    within_fieldset "Date of assessment" do
      fill_in "Day", with: "12"
      fill_in "Month", with: "5"
      fill_in "Year", with: "2023"
    end

    within_fieldset "What was the risk level?" do
      choose "High risk"
    end

    within_fieldset "Who completed the assessment?" do
      choose "Someone else"
      fill_in "Organisation name", with: "Fake org"
    end

    attach_file "risk_assessment_form[risk_assessment_file]", text_file

    click_button "Add risk assessment"

    expect(page).to have_content("You have added 1 risk assessment.")

    within_fieldset "Do you need to add another risk assessment?" do
      choose "No"
    end

    click_button "Continue"

    expect(page).to have_selector(:id, "task-list-3-3-status", text: "Completed")

    click_link "Evaluate notification risk level"

    expect(page).to have_content("This notification has 1 risk assessment added, assessing the risk as high.")

    choose "Medium risk"

    click_button "Save and complete tasks in this section"

    expect(page).to have_selector(:id, "task-list-3-4-status", text: "Completed")
    expect(page).to have_content("You have completed 4 of 6 sections.")

    click_link "Record a corrective action"

    within_fieldset "Have you taken a corrective action for the unsafe or non-compliant product(s)?" do
      choose "Yes"
    end

    click_button "Save and continue"

    within_fieldset "What action is being taken?" do
      choose "Recall of the product from end users"
    end

    within_fieldset "Has the business responsible published product recall information online?" do
      choose "Yes"
      fill_in "Location of recall information", with: "https://www.example.com"
    end

    within_fieldset "What date did the action come in to effect?" do
      fill_in "Day", with: "9"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2024"
    end

    select "ATEX 2016", from: "Under which legislation?"
    select "Consumer Protection Act 1987", from: "Under which legislation?"

    within_fieldset "Which business is responsible?" do
      choose "Trading name"
    end

    within_fieldset "Is the corrective action mandatory?" do
      choose "Yes"
    end

    within_fieldset "In which geographic regions has this corrective action been taken?" do
      check "Great Britain"
      check "European Economic Area (EEA)"
    end

    within_fieldset "Are there any files related to the action?" do
      choose "Yes"
      attach_file "corrective_action_form[document]", text_file
    end

    click_button "Add corrective action"

    expect(page).to have_content("You have added 1 corrective action.")

    within_fieldset "Do you need to add another corrective action?" do
      choose "No"
    end

    click_button "Continue"

    expect(page).to have_selector(:id, "task-list-4-0-status", text: "Completed")
    expect(page).to have_content("You have completed 5 of 6 sections.")

    click_link "Check the notification details and submit"
    click_button "Submit notification"

    expect(page).to have_content("Notification submitted")
  end

  scenario "Creating a notification with form errors" do
    sign_in(user)
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")

    click_link "Search for or add a product"
    click_button "Select", match: :first

    click_button "Continue"
    expect(page).to have_error_messages

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"

    click_link "Add notification details"

    click_button "Save and continue"
    expect(page).to have_error_messages

    add_notification_details_one

    click_button "Save and continue"
    expect(page).to have_error_messages

    add_notification_details_two

    click_button "Save and complete tasks in this section"
    expect(page).to have_error_messages

    add_notification_details_three

    create_business

    click_link "Remove"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/remove-business\/\d{1}/)
    click_button "Remove business"

    click_button "Select", match: :first
    click_button "Use business details"

    check "Retailer"
    click_button "Save and continue"

    click_button "Continue"
    expect(page).to have_error_messages

    within_fieldset "Do you need to add another business?" do
      choose "No"
    end
    click_button "Continue"

    add_product_identification_details

    click_link "Add test reports"
    click_button "Save and continue"
    expect(page).to have_error_messages

    choose "Yes"
    click_button "Save and continue"

    click_button "Save and continue"
    expect(page).to have_error_messages
    fill_in "What is the trading standards officer sample reference number?", with: "12345678"
    fill_in "Day", with: "12"
    fill_in "Month", with: "5"
    fill_in "Year", with: "2023"
    click_button "Save and continue"

    click_button "Add test report"
    expect(page).to have_error_messages

    select "ATEX 2016", from: "Under which legislation?"
    fill_in "Which standard was the product tested against?", with: "EN71"
    fill_in "Day", with: "12"
    fill_in "Month", with: "5"
    fill_in "Year", with: "2023"

    within_fieldset "What was the result?" do
      choose "Fail"
      fill_in "How the product failed", with: "Because it did"
    end

    attach_file "Test report attachment", image_file
    click_button "Add test report"

    expect(page).to have_content("You have added 1 test report.")

    click_button "Continue"
    expect(page).to have_error_messages

    click_link "Remove"
    click_button "Remove test report"

    choose "Yes"
    click_button "Save and continue"

    add_test_report

    click_link "Add supporting images"
    add_supporting_images

    click_link "Add supporting documents"

    click_button "Upload document"
    expect(page).to have_error_messages

    add_supporting_documents

    click_link "Add risk assessments"
    click_link "Add legacy risk assessment"

    click_button "Add risk assessment"
    expect(page).to have_error_messages

    within_fieldset "Date of assessment" do
      fill_in "Day", with: "12"
      fill_in "Month", with: "5"
      fill_in "Year", with: "2023"
    end

    within_fieldset "What was the risk level?" do
      choose "High risk"
    end

    within_fieldset "Who completed the assessment?" do
      choose "Someone else"
      fill_in "Organisation name", with: "Fake org"
    end

    attach_file "risk_assessment_form[risk_assessment_file]", text_file

    click_button "Add risk assessment"

    expect(page).to have_content("You have added 1 risk assessment.")

    click_button "Continue"

    click_link "Remove"
    click_button "Remove risk assessment"

    click_link "Add legacy risk assessment"
    within_fieldset "Date of assessment" do
      fill_in "Day", with: "12"
      fill_in "Month", with: "5"
      fill_in "Year", with: "2023"
    end

    within_fieldset "What was the risk level?" do
      choose "High risk"
    end

    within_fieldset "Who completed the assessment?" do
      choose "Someone else"
      fill_in "Organisation name", with: "Fake org"
    end

    attach_file "risk_assessment_form[risk_assessment_file]", text_file

    click_button "Add risk assessment"

    within_fieldset "Do you need to add another risk assessment?" do
      choose "No"
    end

    click_button "Continue"

    click_link "Evaluate notification risk level"

    click_button "Save and complete tasks in this section"
    expect(page).to have_error_messages

    expect(page).to have_content("This notification has 1 risk assessment added, assessing the risk as high.")

    choose "Medium risk"

    click_button "Save and complete tasks in this section"

    click_link "Record a corrective action"

    click_button "Save and continue"
    expect(page).to have_error_messages

    within_fieldset "Have you taken a corrective action for the unsafe or non-compliant product(s)?" do
      choose "No"
      choose "I need to refer the issue to another authority"
    end

    click_button "Save and continue"

    click_button "Save and complete tasks in this section"

    click_link "Record a corrective action"
    within_fieldset "Have you taken a corrective action for the unsafe or non-compliant product(s)?" do
      choose "Yes"
    end

    click_button "Save and continue"

    click_button "Add corrective action"
    expect(page).to have_error_messages

    within_fieldset "What action is being taken?" do
      choose "Recall of the product from end users"
    end

    within_fieldset "Has the business responsible published product recall information online?" do
      choose "Yes"
      fill_in "Location of recall information", with: "https://www.example.com"
    end

    within_fieldset "What date did the action come in to effect?" do
      fill_in "Day", with: "9"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2024"
    end

    select "ATEX 2016", from: "Under which legislation?"
    select "Consumer Protection Act 1987", from: "Under which legislation?"

    within_fieldset "Which business is responsible?" do
      choose "Trading name"
    end

    within_fieldset "Is the corrective action mandatory?" do
      choose "Yes"
    end

    within_fieldset "Are there any files related to the action?" do
      choose "Yes"
      attach_file "corrective_action_form[document]", text_file
    end

    click_button "Add corrective action"

    within_fieldset "In which geographic regions has this corrective action been taken?" do
      check "Great Britain"
      check "European Economic Area (EEA)"
    end

    expect(page).to have_error_messages

    click_button "Add corrective action"

    expect(page).to have_content("You have added 1 corrective action.")

    within_fieldset "Do you need to add another corrective action?" do
      choose "No"
    end

    click_button "Continue"

    click_link "Check the notification details and submit"
    click_button "Submit notification"

    expect(page).to have_content("Notification submitted")
  end
end

def add_a_product
  click_link "Add a new product"
  select new_product_attributes[:category], from: "Product category"

  fill_in "Product subcategory", with: new_product_attributes[:subcategory]
  fill_in "Manufacturer's brand name", with: new_product_attributes[:brand]
  fill_in "Product name", with: new_product_attributes[:name]
  fill_in "Barcode number (GTIN, EAN or UPC)", with: new_product_attributes[:barcode]
  fill_in "Other product identifiers", with: new_product_attributes[:product_code]
  fill_in "Webpage", with: new_product_attributes[:webpage]

  within_fieldset("Was the product placed on the market before 1 January 2021?") do
    choose when_placed_on_market_answer(new_product_attributes[:when_placed_on_market])
  end

  within_fieldset("Is the product counterfeit?") do
    choose counterfeit_answer(new_product_attributes[:authenticity])
  end

  within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
    page.find("input[value='#{new_product_attributes[:has_markings]}']").choose
  end

  within_fieldset("Select product marking") do
    new_product_attributes[:markings].each { |marking| check(marking) } if new_product_attributes[:has_markings] == "markings_yes"
  end

  select new_product_attributes[:country_of_origin], from: "Country of origin"

  fill_in "Description of product", with: new_product_attributes[:description]

  click_button "Save"

  expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create\/search_for_or_add_a_product/)
  expect(page).to have_content("Search for or add a product")
end

def add_notification_details_one
  fill_in "Notification title", with: "Fake name"
  fill_in "Notification summary", with: "This is a fake summary"
  within_fieldset("Why are you creating the notification?") do
    choose "A product is unsafe or non-compliant"
  end
  click_button "Save and continue"
end

def add_notification_details_two
  within_fieldset "What specific issues make the product unsafe or non-compliant?" do
    check "Product harm"
    select "Chemical", from: "What is the primary harm?"
    fill_in "Provide additional information about the product harm", with: "Fake description"
  end

  within_fieldset "Was the safety issue reported by an overseas regulator?" do
    choose "Yes"
    select "France", from: "Country"
  end

  within_fieldset "Do you want to add your own reference number?" do
    choose "Yes"
    fill_in "Reference number", with: "123456"
  end

  click_button "Save and continue"
end

def add_notification_details_three
  choose "Unknown"
  click_button "Save and complete tasks in this section"
end

def create_business
  click_link "Search for or add a business"
  click_link "Add a new business"
  fill_in "Trading name", with: "Trading name"
  fill_in "Registered or legal name (optional)", with: "Legal name"
  click_button "Save and continue"

  fill_in "Address line 1", with: "123 Fake St"
  fill_in "Address line 2", with: "Fake Heath"
  fill_in "Town or city", with: "Faketon"
  fill_in "County", with: "Fake County"
  fill_in "Post code", with: "FA1 2KE"
  select "United Kingdom", from: "Country"
  click_button "Save and continue"

  fill_in "Full name", with: "Max Mustermann"
  fill_in "Job title or role description", with: "Manager"
  fill_in "Email", with: "max@example.com"
  fill_in "Phone", with: "+441121121212"
  click_button "Save and continue"

  click_button "Use business details"

  check "Retailer"
  click_button "Save and continue"
end

def add_product_identification_details
  click_link "Add product identification details"
  click_link "Add batch numbers"
  fill_in "batch_number", with: "1234, 5678"
  click_button "Save"
  click_button "Continue"
end

def add_test_report
  fill_in "What is the trading standards officer sample reference number?", with: "12345678"
  fill_in "Day", with: "12"
  fill_in "Month", with: "5"
  fill_in "Year", with: "2023"
  click_button "Save and continue"

  select "ATEX 2016", from: "Under which legislation?"
  fill_in "Which standard was the product tested against?", with: "EN71"
  fill_in "Day", with: "12"
  fill_in "Month", with: "5"
  fill_in "Year", with: "2023"

  within_fieldset "What was the result?" do
    choose "Fail"
    fill_in "How the product failed", with: "Because it did"
  end

  attach_file "Test report attachment", image_file
  click_button "Add test report"

  within_fieldset "Do you need to add another test report?" do
    choose "No"
  end

  click_button "Continue"
end

def add_supporting_images
  attach_file "image_upload[file_upload]", image_file
  click_button "Upload image"

  expect(page).to have_content("Supporting image uploaded successfully")

  click_button "Finish uploading images"
end

def add_supporting_documents
  fill_in "Document title", with: "Fake title"
  attach_file "document_form[document]", text_file
  click_button "Upload document"

  expect(page).to have_content("Supporting document uploaded successfully")

  click_button "Finish uploading documents"
end

def create_new_notification(user, team: nil)
  notification = Investigation::Notification.new(complainant_reference: Faker::Lorem.sentence(word_count: 2),
                                                 corrective_action_not_taken_reason: nil,
                                                 corrective_action_taken: nil,
                                                 date_received: 1.day.ago,
                                                 received_type: %w[email phone other].sample,
                                                 is_closed: false,
                                                 coronavirus_related: false,
                                                 description: Faker::Lorem.sentence(word_count: 8),
                                                 user_title: Faker::Name.name)
  if team.present?
    CreateNotification.call(notification:,
                            user: team)
    AddTeamToNotification.call!(
      notification:,
      user: notification.creator_user,
      team: user.team,
      collaboration_class: Collaboration::Access::ReadOnly
    )
  else
    CreateNotification.call(notification:,
                            user:)
  end

  notification
end
