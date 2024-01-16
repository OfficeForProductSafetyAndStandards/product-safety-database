require "rails_helper"

RSpec.describe AuditActivity::Correspondence::AddPhoneCall, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:decorated_activity) { activity.decorate }

  include_context "with phone call correspondence setup"

  let!(:correspondence) { AddPhoneCallToNotification.call!(params.merge(investigation:, user:)).correspondence }
  let(:reporting_user)  { user }
  let(:viewing_user)    { create(:user) }
  let(:activity) { correspondence.activities.find_by!(type: "AuditActivity::Correspondence::AddPhoneCall") }

  describe "#phone_number" do
    context "when no phone number was provded" do
      let(:phone_number) { nil }

      it { expect(decorated_activity.phone_number).to be nil }
    end

    context "when no correspondent name was provided" do
      let(:correspondent_name) { nil }

      it { expect(decorated_activity.phone_number).to eq(phone_number) }
    end

    context "when a correspondent name was provided" do
      it { expect(decorated_activity.phone_number).to eq("(#{phone_number})") }
    end
  end

  describe "#correspondence_date" do
    it { expect(decorated_activity.correspondence_date).to eq(correspondence.correspondence_date.to_formatted_s(:govuk)) }
  end

  describe "#attached" do
    context "with an attached file" do
      it { expect(decorated_activity.attached).to eq("Attached: #{correspondence.transcript_blob.filename}") }
    end

    context "with no attached file" do
      let(:transcript) { nil }

      it { expect(decorated_activity.attached).to be_nil }
    end
  end
end
