require "rails_helper"

RSpec.feature "List cases based on role", :with_elasticsearch, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, :crown_dependency, has_viewed_introduction: true, team: french_team) }
  let(:opss_user) { create(:user, :activated, has_viewed_introduction: true, team: french_team) }
  let(:french_team) { create(:team, country: "country:FR") }

  let!(:gb_case)               { create(:allegation, notifying_country: "country:GB", creator: opss_user) }
  let!(:england_case)          { create(:allegation, notifying_country: "country:GB-ENG", creator: opss_user) }
  let!(:scotland_case)         { create(:allegation, notifying_country: "country:GB-SCT", creator: opss_user) }
  let!(:wales_case)            { create(:allegation, notifying_country: "country:GB-WLS", creator: opss_user) }
  let!(:northern_ireland_case) { create(:allegation, notifying_country: "country:GB-NIR", creator: opss_user) }

  let!(:french_case) { create(:allegation, notifying_country: "country:FR", creator: user) }


  context "when user has crown_dependcy role" do

    before { sign_in user }

    scenario "should not see CROWN_DEPENDENCIES_HIDDEN_NOTIFYING_COUNTRY" do
      click_link "All cases"

      expect(page).to have_listed_case(french_case.pretty_id)

      expect(page).not_to have_listed_case(gb_case.pretty_id)
      expect(page).not_to have_listed_case(england_case.pretty_id)
      expect(page).not_to have_listed_case(scotland_case.pretty_id)
      expect(page).not_to have_listed_case(wales_case.pretty_id)
      expect(page).not_to have_listed_case(northern_ireland_case.pretty_id)
    end
  end

  context "when user has opss role" do

    before { sign_in opss_user }

    scenario "should see CROWN_DEPENDENCIES_HIDDEN_NOTIFYING_COUNTRY" do
      click_link "All cases"

      expect(page).not_to have_listed_case(french_case.pretty_id)

      expect(page).to have_listed_case(gb_case.pretty_id)
      expect(page).to have_listed_case(england_case.pretty_id)
      expect(page).to have_listed_case(scotland_case.pretty_id)
      expect(page).to have_listed_case(wales_case.pretty_id)
      expect(page).to have_listed_case(northern_ireland_case.pretty_id)
    end
  end
end
