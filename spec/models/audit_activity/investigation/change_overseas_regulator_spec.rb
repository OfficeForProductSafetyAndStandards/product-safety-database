require "rails_helper"

RSpec.describe AuditActivity::Investigation::ChangeOverseasRegulator, :with_stubbed_mailer, :with_stubbed_opensearch do
  subject(:metadata) { described_class.build_metadata(investigation) }

  let(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry, is_from_overseas_regulator: true, notifying_country: previous_country) }
  let(:previous_country) { "country:AM" }
  let(:new_country) { "country:US" }
  let(:previous_country_human) { "Armenia" }
  let(:new_country_human) { "United States" }

  let(:activity) { described_class.create(metadata:) }

  before { investigation.update!(notifying_country: new_country) }

  describe ".build_metadata" do
    context "when the case's overseas regulator has been updated" do
      it "produces a Hash of the change" do
        expect(metadata).to eq({
          updates: {
            "notifying_country" => [previous_country, new_country]
          }
        })
      end
    end
  end

  describe "#body" do
    it "returns a string" do
      expect(activity.body).to eq("Overseas regulator changed from #{previous_country_human} to #{new_country_human}")
    end
  end

  describe "#new_country" do
    it "returns the newly assigned country" do
      expect(activity.new_country).to eq(new_country)
    end
  end

  describe "#previous_country" do
    it "returns the previously assigned country" do
      expect(activity.previous_country).to eq(previous_country)
    end
  end
end
