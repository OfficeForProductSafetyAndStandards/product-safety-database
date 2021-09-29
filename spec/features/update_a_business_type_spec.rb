require "rails_helper"

RSpec.feature "Update a business type", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let!(:user)                   { create(:user, :activated, has_viewed_introduction: true) }
  let!(:business)               { create(:business, trading_name: "Acme Ltd") }
  let!(:investigation)          { create(:allegation, creator: user) }
  let!(:investigation_business) { create(:investigation_business, business: business, investigation: investigation, relationship: "manufacturer") }
  let(:new_type)                { "new type" }

  context "when previous type is not other" do
    it "updates correctly" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/businesses"

      click_link "Change business type"

      within_fieldset "Select business type" do
        expect(page).to have_checked_field(investigation_business.relationship.capitalize)
      end

      within_fieldset "Select business type" do
        choose "Other"
        fill_in "Other type", with: new_type
      end

      click_button "Continue"

      expect(page).to have_content(new_type.capitalize)

      click_link "Activity"

      expect(page).to have_content("Business relationship updated")
      expect(page).to have_content("Relationship: #{new_type}")
    end
  end

  context "when previous type is other" do
    before do
      investigation_business.update(relationship: "something else")
    end

    it "updates correctly" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/businesses"

      click_link "Change business type"

      within_fieldset "Select business type" do
        expect(page).to have_checked_field("Other")
        expect(page).to have_field("Other type", with: "something else")
      end

      within_fieldset "Select business type" do
        choose "Manufacturer"
      end

      click_button "Continue"

      expect(page).to have_content("Manufacturer")

      expect(page).to have_content("Business relationship updated")
      expect(page).to have_content("Relationship: manufacturer")
    end
  end
end
