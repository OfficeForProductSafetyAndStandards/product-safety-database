require "rails_helper"

RSpec.describe ResendSecondaryAuthenticationCodeForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(params) }

  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }
  let(:params) do
    {
      mobile_number: mobile_number,
      user: user
    }
  end

  describe "#save!" do
    context "when the user mobile number is verified" do
      let(:user) { create(:user, mobile_number_verified: true) }

      context "with a mobile number with correct format in the params" do
        let(:mobile_number) { "70123456789" }

        it "saves successfully" do
          expect(form.save!).to eq true
        end

        it "does not contain errors" do
          form.save!
          expect(form.errors).to be_empty
        end

        it "does not change the user mobile number" do
          expect {
            form.save!
            user.reload
          }.not_to change(user, :mobile_number)
        end
      end

      context "with a mobile number with incorrect format in the params" do
        let(:mobile_number) { "not-a-phone-number" }

        it "saves successfully" do
          expect(form.save!).to eq true
        end

        it "does not contain errors" do
          form.save!
          expect(form.errors).to be_empty
        end

        it "does not change the user mobile number" do
          expect {
            form.save!
            user.reload
          }.not_to change(user, :mobile_number)
        end
      end

      context "without a mobile number in the params" do
        let(:mobile_number) { "" }

        it "saves successfully" do
          expect(form.save!).to eq true
        end

        it "does not contain errors" do
          form.save!
          expect(form.errors).to be_empty
        end

        it "does not change the user mobile number" do
          expect {
            form.save!
            user.reload
          }.not_to change(user, :mobile_number)
        end
      end
    end

    context "when the user mobile number is not verified" do
      let(:user) { create(:user, mobile_number_verified: false) }

      context "with a mobile number with correct format in the params" do
        let(:mobile_number) { "70123456789" }

        it "saves successfully" do
          expect(form.save!).to eq true
        end

        it "does not contain errors" do
          form.save!
          expect(form.errors).to be_empty
        end

        it "updates the user mobile number to the provided one" do
          expect {
            form.save!
            user.reload
          }.to change(user, :mobile_number).to(mobile_number)
        end
      end

      context "with a mobile number with incorrect format in the params" do
        let(:mobile_number) { "not-a-phone-number" }

        it "fails to save" do
          expect(form.save!).to eq false
        end

        it "contains errors" do
          form.save!
          expect(form.errors.full_messages_for(:mobile_number)).to eq ["Enter your mobile number in the correct format, like 07700 900 982"]
        end

        it "does not change the user mobile number" do
          expect {
            form.save!
            user.reload
          }.not_to change(user, :mobile_number)
        end
      end

      context "without a mobile number in the params" do
        let(:mobile_number) { "" }

        it "fails to save" do
          expect(form.save!).to eq false
        end

        it "contains errors" do
          form.save!
          expect(form.errors.full_messages_for(:mobile_number)).to eq ["Enter your mobile number"]
        end

        it "does not change the user mobile number" do
          expect {
            form.save!
            user.reload
          }.not_to change(user, :mobile_number)
        end
      end
    end
  end
end
