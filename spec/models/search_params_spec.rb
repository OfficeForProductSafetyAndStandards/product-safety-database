require "rails_helper"

RSpec.describe SearchParams do
  subject { described_class.new(search_params) }

  context "when sort_by is blank" do
    let(:search_params) { { sort_by: SearchParams::BLANK } }

    describe 'sort_by_option' do
      it "returns recent by default" do
        expect(subject.sort_by_option).to eq(SearchParams::RECENT)
      end

      it "returns relevant if there is a query present" do
        search_params.merge!(q: 'query')
        expect(subject.sort_by_option).to eq(SearchParams::RELEVANT)
      end
    end

    describe 'sorting_params' do
      it "returns updated_at descending by default" do
        expect(subject.sorting_params).to eq({ updated_at: "desc" })
      end
    end
  end
end
