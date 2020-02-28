require "rails_helper"

RSpec.describe "Ability to edit an investigation", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config, type: :feature do
  let(:investigation) { create(:project) }

  before do
    sign_in
  end

  it "allows to edit the summary" do
    visit investigation_path(investigation)

    click_link "Change summary"

    fill_in "investigation[description]", with: "new description"
    click_on "Update summary"

    expect(page).to have_css("p", text: "new description")
  end
end
