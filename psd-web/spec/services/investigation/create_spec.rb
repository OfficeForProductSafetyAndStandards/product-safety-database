require "rails_helper"

RSpec.describe Investigation::Create do
  let(:complainant_attributes)   { attributes_for(:complainant) }
  let(:investigation_attributes) { attributes_for(:allegation) }
  let(:attachment)    { fixture_file_upload('files/testImage.png') }

  let(:attributes) do
    investigation_attributes.tap do |attrs|
      attrs[:complainant_attributes] = complainant_attributes
    end
  end

  subject { described_class.new(attributes, attachment) }

  describe '#call' do
    it "saves the investigation, complainant and attachments" do
      expect {
        expect(subject.call).to be true
      }.to change { Investigation.where(investigation_attributes).count }.from(0).to(1)
    end
  end

end
