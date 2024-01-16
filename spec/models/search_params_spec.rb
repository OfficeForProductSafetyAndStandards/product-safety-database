RSpec.describe SearchParams do
  subject(:model_instance) { described_class.new(search_params) }

  context "when sort_by is blank" do
    let(:search_params) { { sort_by: nil } }

    context "when there is no search query present" do
      describe "selected_sort_by" do
        it "returns recent" do
          expect(model_instance.selected_sort_by).to eq(SortByHelper::SORT_BY_UPDATED_AT)
        end
      end

      describe "sorting_params" do
        it "returns updated_at descending" do
          expect(model_instance.sorting_params).to eq({ "updated_at" => "desc" })
        end
      end
    end

    context "when there is a query present" do
      before do
        search_params[:q] = "query"
      end

      describe "selected_sort_by" do
        it "returns relevant" do
          expect(model_instance.selected_sort_by).to eq(SortByHelper::SORT_BY_RELEVANT)
        end
      end
    end
  end
end
