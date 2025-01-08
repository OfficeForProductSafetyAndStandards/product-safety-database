require "rails_helper"

RSpec.describe Complainant do
  subject(:complainant) { build(:complainant, investigation:, email_address: nil, name: nil, other_details: nil, phone_number: nil) }

  let(:investigation) { build(:allegation) }

  describe "#save" do
    before { complainant.save }

    context "with an investigation" do
      it "saves the record", :aggregate_failures do
        expect(complainant).to be_persisted
        expect(complainant.errors).to be_empty
      end
    end

    context "with no investigation" do
      let(:investigation) { nil }

      it "generates errors and does not save the record", :aggregate_failures do
        expect(complainant).not_to be_persisted
        expect(complainant.errors).not_to be_empty
      end
    end
  end

  describe "#has_contact_details?" do
    context "when name is not blank" do
      it "returns true", :aggregate_failures do
        complainant.update!(name: "John Doe")
        expect(complainant.has_contact_details?).to be true
      end
    end

    context "when email_address is not blank" do
      it "returns true", :aggregate_failures do
        complainant.update!(email_address: "test@email.com")
        expect(complainant.has_contact_details?).to be true
      end
    end

    context "when phone_number is not blank" do
      it "returns true", :aggregate_failures do
        complainant.update!(phone_number: "077777777")
        expect(complainant.has_contact_details?).to be true
      end
    end

    context "when other_details is not blank" do
      it "returns true", :aggregate_failures do
        complainant.update!(other_details: "From round the corner")
        expect(complainant.has_contact_details?).to be true
      end
    end

    context "when name, other_details and email_address are blank" do
      it "returns false", :aggregate_failures do
        expect(complainant.has_contact_details?).to be false
      end
    end
  end
end
