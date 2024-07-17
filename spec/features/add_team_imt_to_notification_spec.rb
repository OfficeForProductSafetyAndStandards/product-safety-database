require "rails_helper"

RSpec.feature "Add IMT to Notification", :with_opensearch, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:existing_product) { create(:product) }
  let!(:business_one) { create(:business, :online_marketplace, trading_name: "great value", created_at: 1.day.ago) }
  let!(:opss_imt) { create(:team, name: "OPSS Incident Management") }

  before do
    sign_in(user)
  end

  scenario "creating a Serious risk notification with the mininum tasklist flow adds IMT to the notification" do
    create_notification_with_mandatory_tasklist
    choose_risk_level("Serious risk")
    choose_corrective_action_as_no
    submit_notification
    expect(page).to have_content("Notification submitted")
    click_link "Edit submitted notification"

    expect(page).to have_content(opss_imt.name)
  end

  scenario "creating a High risk notification with the mininum tasklist flow adds IMT to the notification" do
    create_notification_with_mandatory_tasklist
    choose_risk_level("High risk")
    choose_corrective_action_as_no
    submit_notification
    expect(page).to have_content("Notification submitted")
    click_link "Edit submitted notification"
    expect(page).to have_content(existing_product.name)
    expect(page).to have_content(business_one.trading_name)
    expect(page).to have_content(opss_imt.name)
  end

  scenario "creating a notification with the mininum tasklist flow and product recall as corrective action adds IMT to the notification" do
    create_notification_with_mandatory_tasklist
    choose_corrective_action("Recall of the product from end users")
    submit_notification
    expect(page).to have_content("Notification submitted")
    click_link "Edit submitted notification"

    expect(page).to have_content(opss_imt.name)
  end

  def create_notification_with_mandatory_tasklist
    visit "/notifications/create"
    click_link "Search for or add a product"
    click_button "Select", match: :first

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"

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
      choose "No"
    end

    within_fieldset "Do you want to add your own reference number?" do
      choose "No"
    end
    click_button "Save and continue"
    choose "Unknown"
    click_button "Save and complete tasks in this section"

    click_link "Search for or add a business"
    click_button "Select", match: :first

    click_button "Use business details"

    check "Retailer"
    click_button "Save and continue"

    within_fieldset "Do you need to add another business?" do
      choose "No"
    end
    click_button "Continue"
  end

  def choose_risk_level(risk_level)
    click_link "Evaluate notification risk level"
    choose risk_level
    click_button "Save and complete tasks in this section"
  end

  def choose_corrective_action(corrective_action)
    click_link "Record a corrective action"

    within_fieldset "Have you taken a corrective action for the unsafe or non-compliant product(s)?" do
      choose "Yes"
    end

    click_button "Save and continue"

    within_fieldset "What action is being taken?" do
      choose corrective_action
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
      choose "great value (Retailer)"
    end

    within_fieldset "Is the corrective action mandatory?" do
      choose "Yes"
    end

    within_fieldset "In which geographic regions has this corrective action been taken?" do
      check "Great Britain"
    end

    within_fieldset "Are there any files related to the action?" do
      choose "No"
    end

    click_button "Add corrective action"
    within_fieldset "Do you need to add another corrective action?" do
      choose "No"
    end

    click_button "Continue"
  end

  def choose_corrective_action_as_no
    click_link "Record a corrective action"

    within_fieldset "Have you taken a corrective action for the unsafe or non-compliant product(s)?" do
      choose "No"
      choose "I don't have enough information to take a corrective action"
    end

    click_button "Save and continue"
    click_button "Save and complete tasks in this section"
  end

  def submit_notification
    click_link "Check the notification details and submit"
    click_button "Submit notification"
  end
end
