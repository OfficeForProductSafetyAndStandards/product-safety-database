require "rails_helper"

RSpec.describe Investigation::Create, :with_stubbed_elasticsearch do
  let(:complainant_attributes)   { attributes_for(:complainant) }
  let(:investigation_attributes) { attributes_for(:allegation) }
  let(:attachment)               { fixture_file_upload('files/testImage.png') }

  let(:attributes) do
    investigation_attributes.tap do |attrs|
      attrs[:complainant_attributes] = complainant_attributes
    end
  end

  subject { described_class.new(attributes, attachment: attachment) }

  describe '#call' do
    let(:investigation) { subject.call }

    it "saves the investigation, complainant and attachments" do
      expect(investigation).to be_persisted

      expect(Complainant.find_by(complainant_attributes)).to eq(investigation.complainant)

      expect(investigation.documents).to be_attached

      attached_blob = investigation.documents.first.blob
      expect(attached_blob.filename).to eq(attachment.original_filename)
    end

    context 'without attachment' do
      let(:attachment) { nil }

      it "saves the investigation and complainant" do
        expect(investigation).to be_persisted
        expect(Complainant.find_by(complainant_attributes)).to eq(investigation.complainant)
        expect(investigation.documents).to_not be_attached
      end
    end
  end

end
