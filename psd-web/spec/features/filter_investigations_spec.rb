require "rails_helper"

RSpec.feature "Case filtering", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:organisation) { create(:organisation) }
  let(:team) { create(:team, organisation: organisation) }
  let(:other_team) { create(:team, organisation: organisation, name: "other team") }
  let(:user) { create(:user, :activated, organisation: organisation, teams: [team]) }
  let(:other_user_same_team) { create(:user, :activated, name: "other user same team", organisation: organisation, teams: [team]) }
  let(:other_user_other_team) { create(:user, :activated, name: "other user other team", organisation: organisation, teams: [other_team]) }

  let!(:investigation) { create(:allegation, assignee: user) }
  let!(:other_user_investigation) { create(:allegation, assignee: other_user_same_team) }
  let!(:other_user_other_team_investigation) { create(:allegation, assignee: other_user_other_team) }
  let!(:other_team_investigation) { create(:allegation, assignee: other_team) }

  let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }

  before do
    Investigation.import refresh: :wait_for
    sign_in(as_user: user)
    visit "/cases"
  end

  scenario "selecting filters only shows other active users in the assigned to and created by filters" do
    expect(page).to have_css("#assigned_to_someone_else_id option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#assigned_to_someone_else_id option[value=\"#{another_inactive_user.id}\"]")

    expect(page).to have_css("#created_by_someone_else_id option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#created_by_someone_else_id option[value=\"#{another_inactive_user.id}\"]")
  end

  scenario "no filters applied shows all cases" do
    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases assigned to me" do
    check "Me", id: "assigned_to_me"
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases assigned to my team" do
    check "My team", id: "assigned_to_team_0"
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases assigned to anyone else" do
    check "Other person or team", id: "assigned_to_someone_else"
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases assigned to another person or team" do
    check "Other person or team", id: "assigned_to_someone_else"
    select other_team.name, from: "assigned_to_someone_else_id"
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)

    check "Other person or team", id: "assigned_to_someone_else"
    select other_user_same_team.name, from: "assigned_to_someone_else_id"
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "combining filters" do
    check "My team", id: "assigned_to_team_0"
    check "Other person or team", id: "assigned_to_someone_else"
    select other_user_other_team.name, from: "assigned_to_someone_else_id"
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end
end
