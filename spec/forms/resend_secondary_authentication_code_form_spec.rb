require "rails_helper"

RSpec.describe ResendSecondaryAuthenticationCodeForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(params) }

  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }
  let(:params) do
    {
      mobile_number:,
      user:
    }
  end

  describe "#valid?" do
    shared_examples "valid form" do
      it "is valid" do
        expect(form).to be_valid
      end

      it "does not contain errors" do
        form.valid?
        expect(form.errors).to be_empty
      end
    end

    context "when the user mobile number is verified" do
      let(:user) { create(:user, mobile_number_verified: true) }

      context "with a mobile number with correct format in the params" do
        let(:mobile_number) { "07012345678" }

        include_examples "valid form"
      end

      context "with a mobile number with incorrect format in the params" do
        let(:mobile_number) { "not-a-phone-number" }

        include_examples "valid form"
      end

      context "without a mobile number in the params" do
        let(:mobile_number) { "" }

        include_examples "valid form"
      end
    end

    context "when the user mobile number is not verified" do
      let(:user) { create(:user, mobile_number_verified: false) }

      context "with a mobile number with correct format in the params" do
        let(:mobile_number) { "07012345678" }

        include_examples "valid form"
      end

      context "with a mobile number with incorrect format in the params" do
        let(:mobile_number) { "not-a-phone-number" }

        it "is invalid" do
          expect(form).not_to be_valid
        end

        it "contains errors" do
          form.valid?
          expect(form.errors.full_messages_for(:mobile_number)).to eq ["Enter your mobile number in the correct format, like 07700 900 982"]
        end
      end

      context "without a mobile number in the params" do
        let(:mobile_number) { "" }

        it "is invalid" do
          expect(form).not_to be_valid
        end

        it "contains errors" do
          form.valid?
          expect(form.errors.full_messages_for(:mobile_number)).to eq ["Enter your mobile number"]
        end
      end
    end
  end
end
