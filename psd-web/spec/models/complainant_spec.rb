require "rails_helper"

RSpec.describe Complainant do
  subject(:complainant) { build(:complainant, investigation: investigation) }
  let(:investigation) { build(:allegation) }

  describe "#save" do
    before { complainant.save }

    context "with an investigation" do
      it "saves the record", :agrregate_failures do
        expect(complainant).to be_persisted
        expect(complainant.errors).to be_empty
      end
    end

    context "with no investigation" do
      let(:investigation) { nil }

      it "generates errors and does not save the record", :agrregate_failures do
        expect(complainant).not_to be_persisted
        expect(complainant.errors).not_to be_empty
      end
    end
  end
end
