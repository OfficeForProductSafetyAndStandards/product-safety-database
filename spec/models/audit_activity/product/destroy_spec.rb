RSpec.describe AuditActivity::Product::Destroy, :with_stubbed_mailer do
  subject(:activity) do
    described_class.create(
      investigation:,
      investigation_product:,
      metadata:
    )
  end

  let(:investigation) { create(:allegation) }
  let!(:investigation_product) { create(:investigation_product) }
  let(:reason) { "test" }
  let(:metadata) { described_class.build_metadata(investigation_product, reason) }

  describe "#metadata" do
    it "returns the metadata" do
      expect(activity.metadata).to eq(activity.read_attribute(:metadata))
    end
  end
end
