require "rails_helper"

RSpec.describe SecondaryAuthentication do
  let(:attempts) { 0 }
  let(:direct_otp) { "11111" }
  let(:direct_otp_sent_at) { Time.zone.now.utc }
  let(:second_factor_attempts_locked_at) { nil }
  let(:user) { create(:user, second_factor_attempts_count: attempts, direct_otp_sent_at:, second_factor_attempts_locked_at:, direct_otp:) }
  let(:secondary_authentication) { described_class.new(user) }

  describe "#valid_otp?" do
    it "increase attempts when checking code" do
      expect {
        secondary_authentication.valid_otp? "123"
      }.to change { user.reload.second_factor_attempts_count }.from(0).to(1)
    end

    it "returns true" do
      expect(secondary_authentication).to be_valid_otp(user.reload.direct_otp)
    end

    context "when maximum attempts exceeded" do
      let(:attempts) { 11 }

      before do
        secondary_authentication.valid_otp? "123"
      end

      it "sets second_factor_attempts_locked_at" do
        expect(user.reload.second_factor_attempts_locked_at).to be_within(1.second).of(Time.zone.now)
      end

      it "resets attempts count" do
        expect(user.reload.second_factor_attempts_count).to eq(0)
      end

      it "does not increase attempts when checking code" do
        expect {
          secondary_authentication.valid_otp? "123"
        }.not_to(change { user.reload.second_factor_attempts_count })
      end

      it "returns false" do
        expect(secondary_authentication).not_to be_valid_otp(user.reload.direct_otp)
      end

      it "sets second_factor_attempts_count after lock cooldown" do
        travel_to(Time.zone.now.utc + (SecondaryAuthentication::MAX_ATTEMPTS_COOLDOWN + 1).seconds) do
          expect {
            secondary_authentication.valid_otp? "123"
          }.to change { user.reload.second_factor_attempts_count }.from(0).to(1)
        end
      end

      it "clears second_factor_attempts_locked_at after lock cooldown" do
        travel_to(Time.zone.now.utc + (SecondaryAuthentication::MAX_ATTEMPTS_COOLDOWN + 1).seconds) do
          secondary_authentication.valid_otp? "123"

          expect(user.reload.second_factor_attempts_locked_at).to be_nil
        end
      end
    end

    context "when using WHITELISTED_2FA_CODE env" do
      shared_examples_for "successful auth" do
        specify do
          expect(secondary_authentication).to be_valid_otp(whitelisted_otp)
        end
      end

      shared_examples_for "failed auth" do
        specify do
          expect(secondary_authentication).not_to be_valid_otp(whitelisted_otp)
        end
      end

      let(:whitelisted_otp) { "12345" }

      let(:application_uris) { %w[foo] }

      let(:vcap_application) do
        { "application_uris" => application_uris }.to_json
      end

      before do
        allow(Rails.configuration).to receive_messages(whitelisted_2fa_code: whitelisted_otp, vcap_application:)
      end

      context "when ENV['VCAP_APPLICATION'] doesn't exist" do
        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] is string" do
        let(:vcap_application) { "foo" }

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] is empty hash" do
        let(:vcap_application) do
          {}.to_json
        end

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] does not have application_uris key" do
        let(:vcap_application) do
          { "foo" => "bar" }.to_json
        end

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris key is string" do
        let(:application_uris) { "foo" }

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris key is empty array" do
        let(:application_uris) { [] }

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris doesn't fit allowed url" do
        let(:application_uris) { %w[foo] }

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris has more than 1 value" do
        let(:application_uris) { ["staging.product-safety-database.service.gov.uk", "psd-pr-594.london.cloudapps.digital"] }

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris is production url" do
        let(:application_uris) { ["www.product-safety-database.service.gov.uk"] }

        it_behaves_like "failed auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris is staging url" do
        let(:application_uris) { ["staging.product-safety-database.service.gov.uk"] }

        it_behaves_like "successful auth"
      end

      context "when ENV['VCAP_APPLICATION'] application_uris is review app url" do
        let(:application_uris) { ["psd-pr-594.london.cloudapps.digital"] }

        it_behaves_like "successful auth"
      end
    end
  end

  describe "#otp_locked?" do
    it "returns false when second_factor_attempts_locked_at is empty" do
      expect(secondary_authentication.otp_locked?).to be(false)
    end

    context "when second_factor_attempts_locked_at is not empty" do
      let(:second_factor_attempts_locked_at) { Time.zone.now.utc }

      it "returns true" do
        expect(secondary_authentication.otp_locked?).to be(true)
      end

      it "returns false when cooldown passed" do
        travel_to(second_factor_attempts_locked_at + (SecondaryAuthentication::MAX_ATTEMPTS_COOLDOWN + 1).seconds) do
          expect(secondary_authentication.otp_locked?).to be(false)
        end
      end
    end
  end
end
