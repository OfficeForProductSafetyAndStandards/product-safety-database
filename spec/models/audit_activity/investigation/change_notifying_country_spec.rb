require "rails_helper"

RSpec.describe AuditActivity::Investigation::ChangeNotifyingCountry, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:metadata) { described_class.build_metadata(investigation) }

  let(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry, notifying_country: previous_country) }
  let(:previous_country) { "country:GB-ENG" }
  let(:new_country) { "country:GB-SCT" }

  let(:activity) { described_class.create(metadata: metadata) }

  before { investigation.update!(notifying_country: new_country) }

  describe ".build_metadata" do
    context "when the case's country has been updated" do
      it "produces a Hash of the change" do
        expect(metadata).to eq({
          updates: {
            "notifying_country" => [previous_country, new_country]
          }
        })
      end
    end

    context "when the case'scountry has not been updated" do
      subject(:metadata) { described_class.build_metadata(stale_investigation) }

      let(:stale_investigation) { create(:enquiry, coronavirus_related: previous_country) }

      it "produces a Hash with no changes" do
        expect(metadata).to eq({
          updates: {}
        })
      end
    end
  end

  describe "#body" do
    it "returns a string" do
      expect(activity.body).to eq("Notifying country changed from #{previous_country} to #{new_country}")
    end
  end
end
