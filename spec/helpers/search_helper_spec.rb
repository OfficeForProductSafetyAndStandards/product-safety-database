require "rails_helper"

RSpec.describe SearchHelper, type: :helper do
  subject(:search_helper) { described_class.new }

  let(:user) { double("User", id: 1, team:) }
  let(:team) { double("Team", id: 1, users: [user]) }
  let(:params) { ActionController::Parameters.new(q: "test_query", page: "1", sort_by: "name", sort_dir: "asc", page_name: "example_page") }
  let(:search_params) { instance_double(SearchParams, q: "test_query", case_owner: nil) }
  let(:opensearch_query) { instance_double(OpensearchQuery) }

  before do
    allow(helper).to receive(:params).and_return(params)
    allow(SearchParams).to receive(:new).and_return(search_params)
    allow(OpensearchQuery).to receive(:new).and_return(opensearch_query)
    search_helper
  end

  # set_search_params
  describe "#set_search_params" do
    it "initializes @search with query_params excluding :page_name" do
      search_helper.set_search_params
      expect(assigns(:search)).to eq(search_params)
    end
  end
end
# search_params
# search_query(user)
# query_params
# sorting_params
# filter_params(user)
# page_number
# get_owner_filter(user)
# compute_excluded_terms(user)
# format_owner_terms(owner_array)
