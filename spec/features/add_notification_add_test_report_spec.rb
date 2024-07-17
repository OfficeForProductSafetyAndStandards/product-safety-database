require "rails_helper"

RSpec.feature "Notification add test report", :with_opensearch, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:existing_product) { create(:product) }
  let(:new_product_attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end

  before do
    sign_in(user)

    existing_product
  end

  scenario "Creating a notification with the normal flow reported reason" do
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
    fill_in "Notification title", with: "Fake name"
    fill_in "Notification summary", with: "This is a fake summary"
    within_fieldset("Why are you creating the notification?") do
      choose "A product is unsafe or non-compliant"
    end
    click_button "Save and continue"

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

    choose "Unknown"
    click_button "Save and complete tasks in this section"

    expect(page).to have_selector(:id, "task-list-1-0-status", text: "Completed")
    expect(page).to have_selector(:id, "task-list-1-1-status", text: "Completed")
    expect(page).to have_selector(:id, "task-list-1-2-status", text: "Completed")
    expect(page).to have_content("You have completed 2 of 6 sections.")

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

    click_link "Add product identification details"
    click_link "Add batch numbers"
    fill_in "batch_number", with: "1234, 5678"
    click_button "Save"
    click_button "Continue"

    click_link "Add test reports"

    expect(page).to have_h1("Was the test funded under the OPSS Local Authority sampling protocol?")

    expect(page).to have_content("This is only relevant if you are a Local Authority user. If you are not a Local Authority user, select 'No'.")
  end
end
