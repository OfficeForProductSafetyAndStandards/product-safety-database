require "rails_helper"

RSpec.describe SearchParams do
  subject(:model_instance) { described_class.new(search_params) }

  context "when sort_by is blank" do
    let(:search_params) { { sort_by: SearchParams::BLANK } }

    describe "sort_by_option" do
      it "returns recent by default" do
        expect(model_instance.sort_by_option).to eq(SearchParams::RECENT)
      end

      it "returns relevant if there is a query present" do
        search_params[:q] = "query"
        expect(model_instance.sort_by_option).to eq(SearchParams::RELEVANT)
      end
    end

    describe "sorting_params" do
      it "returns updated_at descending by default" do
        expect(model_instance.sorting_params).to eq({ updated_at: "desc" })
      end
    end
  end
end
