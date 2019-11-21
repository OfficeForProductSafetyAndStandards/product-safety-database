require "rails_helper"

RSpec.describe "Filtering the investigations list", type: :request, with_keycloak_config: true do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }
  let(:investigation) { create(:allegation) }

  let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }

  before do
    stub_elasticsearch_results
    sign_in(as_user: user)
  end

  def stub_elasticsearch_results
    results = double("es", records: nil, results: [double("results", _id: investigation.id, merge: nil)])
    allow(Investigation).to receive(:full_search).and_return(double(paginate: results))
  end

  context "when the user wishes to filter by who the case is assigned to" do
    before { get "/cases" }

    it "only shows other active users" do
      expect(response.body).to have_css("#assigned_to_someone_else_id option[value=\"#{another_active_user.id}\"]")
      expect(response.body).not_to have_css("#assigned_to_someone_else_id option[value=\"#{another_inactive_user.id}\"]")
    end
  end

  context "when the user wishes to filter by who the case was created by" do
    before { get "/cases" }

    it "only shows other active users" do
      expect(response.body).to have_css("#created_by_someone_else_id option[value=\"#{another_active_user.id}\"]")
      expect(response.body).not_to have_css("#created_by_someone_else_id option[value=\"#{another_inactive_user.id}\"]")
    end
  end
end
