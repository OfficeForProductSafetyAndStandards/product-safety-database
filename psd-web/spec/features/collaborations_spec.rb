require "rails_helper"

RSpec.describe "Collaborations", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:owner_team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: owner_team }
  let(:editor_team) { create :team, name: "editor" }
  let(:read_only_team) { create :team, name: "read only"}
  let(:investigation) { create(:allegation, creator: user) }

  before do
    sign_in user
    AddTeamToAnInvestigation.call!(investigation: investigation, current_user: user, include_message: false, collaborator_id: editor_team.id)
    investigation.read_only_collaborations.create!(collaborator: read_only_team)
  end

  it "lists all the teams" do
    visit "/cases/#{investigation.pretty_id}/teams"

    expect(page).to have_css("table tbody tr:nth-child(1) th:nth-child(1)", text: "#{owner_team.name} Case creator")
    expect(page).to have_css("table tbody tr:nth-child(1) td:nth-child(2)", text: "Case owner")

    expect(page).to have_css("table tbody tr:nth-child(2) th:nth-child(1)", text: editor_team.name)
    expect(page).to have_css("table tbody tr:nth-child(2) td:nth-child(2)", text: "Edit full case")

    expect(page).to have_css("table tbody tr:nth-child(3) th:nth-child(1)", text: read_only_team.name)
    expect(page).to have_css("table tbody tr:nth-child(3) td:nth-child(2)", text: "Read only case")
  end
end
