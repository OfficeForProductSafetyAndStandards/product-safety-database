require "rails_helper"

RSpec.describe Investigation, :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify do
  describe ".full_search" do
    context "when sorting by created_at" do
      let(:dates) do
        [Time.zone.now,
         Time.zone.now - 2.hours,
         Time.zone.now - 1.hour]
      end
      let(:expected_order) { dates.sort.reverse }
      let(:sorting_params) do
        { created_at: "desc" }
      end
      let(:query) { ElasticsearchQuery.new(nil, {}, sorting_params) }
      let(:result) { described_class.full_search(query) }

      before do
        dates.each { |created_at| create(:allegation, created_at: created_at) }
        described_class.__elasticsearch__.import force: true, refresh: :wait
      end

      it "lists cases correctly sorted" do
        investigations = Investigation.eager_load(
          :complainant,
          :creator_user
        ).where(id: result.results.map(&:_id))

        expect(investigations.map {|i| i.created_at}).to eq(expected_order)
      end
    end
  end
end
