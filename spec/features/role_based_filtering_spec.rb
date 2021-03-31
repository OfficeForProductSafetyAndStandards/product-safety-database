require "rails_helper"

RSpec.feature "List cases based on role", :with_elasticsearch, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, :crown_dependency, has_viewed_introduction: true) }

  let!(:gb_case)               { create(:allegation, notifying_country: "country:GB") }
  let!(:england_case)          { create(:allegation, notifying_country: "country:GB-ENG") }
  let!(:scotland_case)         { create(:allegation, notifying_country: "country:GB-SCT") }
  let!(:wales_case)            { create(:allegation, notifying_country: "country:GB-WLS") }
  let!(:northern_ireland_case) { create(:allegation, notifying_country: "country:GB-NIR") }

  let!(:french_case) { create(:allegation, notifying_country: "country:FR") }

  before { sign_in user }


  scenario "should not see CROWN_DEPENDENCIES_HIDDEN_NOTIFYING_COUNTRY" do
    click_link "All cases"


    expect(page).to have_listed_case(french_case.pretty_id)

    save_and_open_page
    expect(page).not_to have_listed_case(gb_case.pretty_id)
    expect(page).not_to have_listed_case(england_case.pretty_id)
    expect(page).not_to have_listed_case(scotland_case.pretty_id)
    expect(page).not_to have_listed_case(wales_case.pretty_id)
    expect(page).not_to have_listed_case(northern_ireland_case.pretty_id)
  end
end
