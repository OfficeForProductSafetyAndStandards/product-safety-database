require "rails_helper"

RSpec.describe AddPhoneCallToCase, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:result) { described_class.call(params) }

  include_context "with phone call correspondence setup"

  before do
    params[:investigation] = investigation
    params[:user]          = user
  end

  describe "#call" do
    context "when no investigation is provided" do
      let(:investigation) { nil }

      it { expect(result).to be_a_failure }
      it { expect(result.error).to eq("No investigation supplied") }
    end

    context "when no user is provided" do
      let(:user) { nil }

      it { expect(result).to be_a_failure }
      it { expect(result.error).to eq("No user supplied") }
    end
  end

  describe "when providing all necessary arguments" do
    it "creates a correspondence" do
      expect(result.correspondence).to have_attributes(
        transcript: instance_of(ActiveStorage::Attached::One),
        correspondence_date:,
        correspondent_name:,
        overview:,
        details:
      )
    end

    it "creates an audit log", :aggregate_failures do
      result
      activity = result.correspondence.activities.find_by!(type: "AuditActivity::Correspondence::AddPhoneCall")

      expect(activity.investigation).to eq(investigation)
      expect(activity.added_by_user).to eq(user)
      expect(activity.correspondence).to eq(result.correspondence)
    end

    it "notifies the relevant users", :with_test_queue_adapter do
      expect { described_class.call(params) }.to have_enqueued_mail(NotifyMailer, :notification_updated).with(
        investigation.pretty_id,
        investigation.owner_team.name,
        investigation.owner_team.email,
        "Phone call details added to the notification by #{user.decorate.display_name(viewer: user)}.",
        "Notification updated"
      )
    end
  end
end
