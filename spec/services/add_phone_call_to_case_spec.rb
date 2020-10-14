require "rails_helper"

RSpec.describe AddPhoneCallToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with phone call correspondence setup"

  subject(:result) { described_class.call(params) }

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
        correspondence_date: correspondence_date,
        correspondent_name: correspondent_name,
        overview: overview,
        details: details
      )
    end

    it "creates an audit log", :aggregate_failures do
      expect(result.correspondence.activity.investigation).to eq(investigation)
      expect(result.correspondence.activity.source.user).to eq(user)
      expect(result.correspondence.activity.correspondence).to eq(result.correspondence)
    end

    it "notifies the relevant users", :with_test_queue_adapter do
      expect { described_class.call(params) }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(a_hash_including(args: [
        investigation.pretty_id,
        investigation.owner_team.name,
        investigation.owner_team.email,
        "Phone call details added to the Allegation by #{result.correspondence.activity.source.show}.",
        "Allegation updated"
      ]))
    end
  end
end
