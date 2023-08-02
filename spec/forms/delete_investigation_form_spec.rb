require "rails_helper"

RSpec.describe DeleteInvestigationForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(investigation:) }

  let(:investigation) { create(:allegation) }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no investigation" do
      let(:investigation) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with investigation that has associated products" do
      let(:investigation) { create(:allegation, :with_products) }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
