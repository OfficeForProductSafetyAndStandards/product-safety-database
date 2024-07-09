require "rails_helper"

RSpec.describe BulkProductsUpload, :with_stubbed_mailer, :with_stubbed_notify do
  subject(:destroy_abandoned_records) { described_class.destroy_abandoned_records! }

  let(:bulk_products_upload_one) { create(:bulk_products_upload) }
  let(:bulk_products_upload_two) { create(:bulk_products_upload, :submitted) }
  let(:bulk_products_upload_three) { create(:bulk_products_upload, updated_at: 10.days.ago) }
  let(:bulk_products_upload_four) { create(:bulk_products_upload, :submitted, updated_at: 10.days.ago) }

  context "with multiple bulk products uploads in different states" do
    before do
      bulk_products_upload_one
      bulk_products_upload_two
      bulk_products_upload_three
      bulk_products_upload_four
    end

    it "deletes records that were last updated more than 3 days ago and have not been submitted" do
      expect { destroy_abandoned_records }.to change(described_class, :count).by(-1)
    end
  end
end
