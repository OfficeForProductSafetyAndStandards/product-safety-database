require "rails_helper"

RSpec.describe SearchParams do
  subject(:model_instance) { described_class.new(search_params) }

  context "when sort_by is blank" do
    let(:search_params) { { sort_by: SearchParams::BLANK } }

    context "when there is no search query present" do
      describe "sort_by_option" do
        it "returns recent" do
          expect(model_instance.sort_by_option).to eq(SearchParams::RECENT)
        end
      end

      describe "sorting_params" do
        it "returns updated_at descending" do
          expect(model_instance.sorting_params).to eq({ updated_at: "desc" })
        end
      end
    end

    context "when there is a query present" do
      before do
        search_params[:q] = "query"
      end

      describe "sort_by_option" do
        it "returns relevant" do
          expect(model_instance.sort_by_option).to eq(SearchParams::RELEVANT)
        end
      end
    end
  end
end
