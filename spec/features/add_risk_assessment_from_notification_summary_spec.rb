require "rails_helper"

RSpec.describe "Adding a PRISM risk assessment to a submitted notification", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let!(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:product_one) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let!(:notification) { create(:notification, :with_business, products: [product_one], creator: user) }

  before do
    sign_in(user)
    visit new_investigation_prism_risk_assessment_path(notification)
  end

  context "when there are related risk assessments" do
    let!(:risk_assessment_one) { create(:prism_risk_assessment, :submitted, products: [product_one], name: "Risk Assessment 1", created_by_user_id: user.id) }
    let!(:risk_assessment_two) { create(:prism_risk_assessment, :submitted, products: [product_one], name: "Risk Assessment 2", created_by_user_id: user.id) }

    before do
      visit new_investigation_prism_risk_assessment_path(notification)
    end

    it "displays the risk assessments table" do
      expect(page).to have_content("Related risk assessments")
      expect(page).to have_content("Select a related risk assessment to add to the notification. If you find that the assessment doesn't fit your notification, you have the choice to either start a new assessment or attach one you've previously created.")
      expect(page).to have_content("Assessment title")
      expect(page).to have_content("Created by")
      expect(page).to have_content("Last updated")
      expect(page).to have_content(risk_assessment_one.name)
      expect(page).to have_content(risk_assessment_two.name)
      expect(page).to have_link("View")
      expect(page).to have_button("Add")
    end

    context "when there are more than 11 risk assessments" do
      before do
        12.times do |i|
          create(:prism_risk_assessment, :submitted, products: [product_one], name: "Risk Assessment #{i + 3}", created_by_user_id: user.id)
        end
        visit new_investigation_prism_risk_assessment_path(notification)
      end

      it "displays the header and footer" do
        expect(page).to have_text("Assessment title", count: 2)
        expect(page).to have_text("Created by", count: 2)
        expect(page).to have_text("Last updated", count: 2)
        expect(page).to have_css("tfoot")
        expect(page).to have_css("tfoot th", count: 5)
      end
    end
  end

  context "when there are no related risk assessments" do
    it "displays the no risk assessments message" do
      expect(page).to have_content("There are no risk assessments for #{product_one.name}")
      expect(page).to have_content("You can start a new assessment")
    end
  end

  it "displays action buttons and links" do
    expect(page).to have_link("Start a new risk assessment")
    expect(page).to have_link("Attach existing risk assessment")
  end

  context "when adding a risk assessment" do
    let!(:risk_assessment) { create(:prism_risk_assessment, :submitted, products: [product_one], name: "Test Risk Assessment", created_by_user_id: user.id) }

    before do
      visit new_investigation_prism_risk_assessment_path(notification)
    end

    it "allows adding a risk assessment to the notification" do
      click_button "Add"
      expect(page).to have_current_path(notification_path(notification))
      expect(page).to have_content("The #{risk_assessment.name} risk assessment has been added to the notification.")
    end
  end
end
