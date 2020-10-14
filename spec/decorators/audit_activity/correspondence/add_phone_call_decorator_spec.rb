require "rails_helper"

RSpec.describe AuditActivity::Correspondence::AddPhoneCall, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with phone call correspondence setup"

  subject(:decorated_activity) { correspondence.activity.decorate }

  let!(:correspondence) { AddPhoneCallToCase.call!(params.merge(investigation: investigation, user: user)).correspondence }
  let(:reporting_user)  { user }
  let(:viewing_user)    { create(:user) }

  describe "#phone_call_by" do
    it {
      expect(decorated_activity.phone_call_by(viewing_user))
        .to eq("Phone call by #{correspondence.activity.source.show(viewing_user)}, #{correspondence.activity.created_at.to_s(:govuk)}")
    }
  end

  describe "#phone_number" do
    context "when no phone umber was provded" do
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
    it { expect(decorated_activity.correspondence_date).to eq(correspondence.correspondence_date.to_s(:govuk)) }
  end

  describe "#attached" do
    it { expect(decorated_activity.attached).to eq("Attached: #{correspondence.transcript_blob.filename}") }
  end
end
