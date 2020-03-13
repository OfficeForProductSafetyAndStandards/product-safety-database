require "rails_helper"

RSpec.describe TwoFactorAuthenticationForm do
  subject(:form) { described_class.new(otp_code: otp_code) }

  describe "#valid?" do
    before { form.validate }

    context "when the two factor code is blank" do
      let(:otp_code) { "" }

      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        expect(form.errors.full_messages_for(:otp_code)).to eq(["Enter the security code"])
      end
    end

    context "when the two factor code has less digits than the required ones" do
      let(:otp_code) { rand.to_s[2..Devise.otp_length] }

      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        expect(form.errors.full_messages_for(:otp_code)).to eq(["You haven’t entered enough numbers"])
      end
    end

    context "when the two factor code has more digits than the required ones" do
      let(:otp_code) { rand.to_s[2..Devise.otp_length + 2] }

      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        expect(form.errors.full_messages_for(:otp_code)).to eq(["You’ve entered too many numbers"])
      end
    end

    context "when the two factor code has the right number of digits" do
      let(:otp_code) { rand.to_s[2..Devise.otp_length + 1] }

      it "is valid" do
        expect(form).to be_valid
      end

      it "does not contain error messages" do
        expect(form.errors).to be_empty
      end
    end
  end
end
