require "rails_helper"

RSpec.describe DeleteOldExportsJob, :with_stubbed_antivirus, :with_stubbed_mailer, type: :job do
  subject(:job) { described_class.new }

  let(:user) { create(:user) }

  let!(:old_product_export) do
    product_export = ProductExport.create!(
      created_at: 8.days.ago,
      user_id: user.id
    )
    product_export.export_file.attach(io: StringIO.new("test content"), filename: "test_old_product_export.xlsx")
    product_export
  end

  let!(:recent_product_export) do
    product_export = ProductExport.create!(
      created_at: 1.day.ago,
      user_id: user.id
    )
    product_export.export_file.attach(io: StringIO.new("test content"), filename: "test_recent_product_export.xlsx")
    product_export
  end

  let!(:old_case_export) do
    case_export = CaseExport.create!(
      created_at: 8.days.ago,
      user_id: user.id
    )
    case_export.export_file.attach(io: StringIO.new("test content"), filename: "test_old_case_export.xlsx")
    case_export
  end

  let!(:recent_case_export) do
    case_export = CaseExport.create!(
      created_at: 1.day.ago,
      user_id: user.id
    )
    case_export.export_file.attach(io: StringIO.new("test content"), filename: "test_recent_case_export.xlsx")
    case_export
  end

  let(:old_case_export_file_id) { old_case_export.export_file.attachment.id }
  let(:recent_case_export_file_id) { recent_case_export.export_file.attachment.id }
  let(:old_product_export_file_id) { old_product_export.export_file.attachment.id }
  let(:recent_product_export_file_id) { recent_product_export.export_file.attachment.id }

  # rubocop:disable RSpec/MultipleExpectations
  describe "#perform" do
    it "deletes old ProductExport instances and their attached files" do
      expect { job.perform }.to change(ProductExport, :count).by(-1)
      expect(ProductExport.all).not_to include(old_product_export)
      expect(ProductExport.all).to include(recent_product_export)
      expect(ActiveStorage::Attachment.exists?(old_product_export_file_id)).to eq false
      expect(ActiveStorage::Attachment.exists?(recent_product_export_file_id)).to eq true
    end

    it "deletes old CaseExport instances and their attached files" do
      expect { job.perform }.to change(CaseExport, :count).by(-1)
      expect(CaseExport.all).not_to include(old_case_export)
      expect(CaseExport.all).to include(recent_case_export)
      expect(ActiveStorage::Attachment.exists?(old_case_export_file_id)).to eq false
      expect(ActiveStorage::Attachment.exists?(recent_case_export_file_id)).to eq true
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
