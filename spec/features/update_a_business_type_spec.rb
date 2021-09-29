require "rails_helper"

RSpec.feature "Update a business type", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let!(:owner_user)             { create(:user, :activated, has_viewed_introduction: true,) }
  let!(:same_team_user)         { create(:user, :activated, has_viewed_introduction: true, team: owner_user.team) }
  let!(:business)               { create(:business, trading_name: "Acme Ltd") }
  let!(:investigation)          { create(:allegation, creator: owner_user) }
  let!(:investigation_business) { create(:investigation_business, business: business, investigation: investigation, relationship: "manufacturer") }
  let(:new_type)                { "new type" }

  context "when previous type is not other" do
    it "updates correctly" do
      sign_in same_team_user
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
      expect_email_to_be_correctly_delivered(new_type)
    end
  end

  context "when previous type is other" do
    before do
      investigation_business.update(relationship: "something else")
    end

    it "updates correctly" do
      sign_in same_team_user
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

      click_link "Activity"

      expect(page).to have_content("Business relationship updated")
      expect(page).to have_content("Relationship: manufacturer")
      expect_email_to_be_correctly_delivered("manufacturer")
    end
  end

  def expect_email_to_be_correctly_delivered(new_relationship)
    email = delivered_emails.last
    expect(email.recipient).to eq owner_user.email
    expect(email.personalization[:update_text]).to eq "Business relationship between #{business.trading_name} and the allegation was changed to #{new_relationship} by #{same_team_user.name}."
    expect(email.personalization[:subject_text]).to eq "Business relationship updated"
  end
end
