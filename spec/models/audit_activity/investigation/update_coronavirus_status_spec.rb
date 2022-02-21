require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateCoronavirusStatus, :with_stubbed_mailer, :with_stubbed_opensearch do
  subject(:metadata) { described_class.build_metadata(investigation) }

  let(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry, coronavirus_related: previous_status) }
  let(:previous_status) { false }
  let(:new_status) { true }

  let(:activity) { described_class.create(metadata:) }

  before { investigation.update!(coronavirus_related: new_status) }

  describe ".build_metadata" do
    context "when the case's coronavirus status has been updated" do
      it "produces a Hash of the change" do
        expect(metadata).to eq({
          updates: {
            "coronavirus_related" => [previous_status, new_status]
          }
        })
      end
    end

    context "when the case's coronavirus status has not been updated" do
      subject(:metadata) { described_class.build_metadata(stale_investigation) }

      let(:stale_investigation) { create(:enquiry, coronavirus_related: previous_status) }

      it "produces a Hash with no changes" do
        expect(metadata).to eq({
          updates: {}
        })
      end
    end
  end

  describe "#title" do
    context "when new status is true" do
      it "returns a string" do
        expect(activity.title).to eq("Status updated: coronavirus related")
      end
    end

    context "when new status is false" do
      let(:previous_status) { true }
      let(:new_status) { false }

      it "returns a string" do
        expect(activity.title).to eq("Status updated: not coronavirus related")
      end
    end
  end

  describe "#body" do
    context "when new status is true" do
      it "returns a string" do
        expect(activity.body).to eq("The case is related to the coronavirus outbreak.")
      end
    end

    context "when new status is false" do
      let(:previous_status) { true }
      let(:new_status) { false }

      it "returns a string" do
        expect(activity.body).to eq("The case is not related to the coronavirus outbreak.")
      end
    end
  end

  describe "#new_status" do
    it "returns the new coronavirus status" do
      expect(activity.new_status).to eq(new_status)
    end
  end
end
