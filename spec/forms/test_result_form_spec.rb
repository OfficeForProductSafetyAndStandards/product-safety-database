require "rails_helper"

RSpec.describe TestResultForm, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:form) { described_class.new(params) }

  let(:params) { attributes_for(:test_result) }
  let(:investigation) { params.delete(:investigation) }

  before { investigation }

  describe "#cache_files" do
    it "chaches the documents files" do
      expect { form.cache_files! }.to change { ActiveStorage::Blob.count }.by(1)
    end

    it "stores the blob signed id" do
      expect { form.cache_files! }.to change { form.existing_documents_ids.size }.by(1)
    end
  end
end
