require "rails_helper"

class DummyElasticSearchResult
  attr_accessor :_id
  def merge(_)
  end
end

describe "Filtering the investigations list", type: :request, with_keycloak_config: true do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }
  let(:investigation) { create(:allegation) }

  before do
    stub_elasticsearch_results
    @another_active_user = create(:user, :activated, organisation: user.organisation, teams: [team])
    @another_inactive_user = create(:user, organisation: user.organisation, teams: [team])
    sign_in(as_user: user)
  end

  def stub_elasticsearch_results
    result = DummyElasticSearchResult.new
    result._id = investigation.id

    results = OpenStruct.new(results: [result])
    allow_any_instance_of(InvestigationsController).to receive(:search_for_investigations).and_return(results)
  end

  context "when the user wishes to filter by who the case is assigned to" do
    before { get "/cases" }

    it "shows other active users" do
      expect(response.body).to have_css("#assigned_to_someone_else_id option[value=\"#{@another_active_user.id}\"]")
    end

    it "does not show other inactive users" do
      expect(response.body).not_to have_css("#assigned_to_someone_else_id option[value=\"#{@another_inactive_user.id}\"]")
    end
  end

  context "when the user wishes to filter by who the case was created by" do
    before { get "/cases" }

    it "shows other active users" do
      expect(response.body).to have_css("#created_by_someone_else_id option[value=\"#{@another_active_user.id}\"]")
    end

    it "does not show other inactive users" do
      expect(response.body).not_to have_css("#created_by_someone_else_id option[value=\"#{@another_inactive_user.id}\"]")
    end
  end
end
