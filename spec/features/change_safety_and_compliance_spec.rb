require "rails_helper"

RSpec.feature "Change safety and compliance details for a case", :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, creator: user, reported_reason: "unsafe_and_non_compliant", hazard_type: "burns", hazard_description: "FIRE FIRE FIRE", non_compliant_reason: "Covered in petrol") }

  context "when user is allowed to edit the case" do
    it "does not allow user to change country" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}"
      expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Unsafe and non-compliant")
      expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: investigation.hazard_type)
      expect(page.find("dt", text: "Description of hazard")).to have_sibling("dd", text: investigation.hazard_description)
      expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: investigation.non_compliant_reason)

      click_link "Change hazard_type"

      expect(page).to have_css("h1", text: "Why are you reporting this product?")
    end
  end
end
