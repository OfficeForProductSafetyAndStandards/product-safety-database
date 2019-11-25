require "rails_helper"

RSpec.feature "Filtering the investigations list", type: :feature, with_keycloak_config: true do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }
  let(:investigation) { create(:allegation) }

  let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }

  before do
    results = double("es", records: nil, results: [double("results", _id: investigation.id, merge: nil)])
    allow(Investigation).to receive(:full_search).and_return(double(paginate: results))

    sign_in(as_user: user)
  end

  scenario "only shows other active users in the assigned to and created by filters" do
    visit "/cases"

    expect(page).to have_css("#assigned_to_someone_else_id option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#assigned_to_someone_else_id option[value=\"#{another_inactive_user.id}\"]")

    expect(page).to have_css("#created_by_someone_else_id option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#created_by_someone_else_id option[value=\"#{another_inactive_user.id}\"]")
  end

end
