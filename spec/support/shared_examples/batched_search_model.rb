RSpec.shared_examples "a batched search model", :with_opensearch do
  describe "#search_in_batches" do
    before do
      create_list(factory_name, 4)
      described_class.__elasticsearch__.create_index! force: true
      described_class.import refresh: :wait_for
    end

    context "when searching in batches" do
      let(:es_query) { OpensearchQuery.new(nil, {}, {}) }
      let(:expected_ids) { described_class.all.map(&:id).map(&:to_s) }

      # rubocop:disable RSpec/MultipleExpectations
      it "returns the expected objects" do
        expect(described_class.search_in_batches(es_query, 1).map(&:id)).to match_array(expected_ids)
        expect(described_class.search_in_batches(es_query, 2).map(&:id)).to match_array(expected_ids)
        expect(described_class.search_in_batches(es_query, 100).map(&:id)).to match_array(expected_ids)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
