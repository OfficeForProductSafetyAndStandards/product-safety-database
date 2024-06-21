require "rails_helper"

RSpec.describe DeleteAbandonedBulkProductsUploadsJob, type: :job do
  describe "#perform" do
    it "calls destroy_abandoned_records! on BulkProductsUpload" do
      allow(BulkProductsUpload).to receive(:destroy_abandoned_records!)

      described_class.new.perform

      expect(BulkProductsUpload).to have_received(:destroy_abandoned_records!)
    end
  end
end
