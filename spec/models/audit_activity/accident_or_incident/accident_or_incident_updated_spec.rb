require "rails_helper"

RSpec.describe AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated, :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:activity) { investigation.reload.activities.first }

  let(:investigation) { create(:allegation, :with_products, creator: user) }
  let(:user) { create(:user) }
  let(:date) { Time.zone.today }
  let(:severity) { "high" }
  let(:new_severity) { "serious" }
  let(:usage) { "during_normal_use" }
  let(:new_usage) { "during_misuse" }
  let(:investigation_product) { create(:investigation_product) }
  let(:accident_or_incident) do
    AddAccidentOrIncidentToCase.call!(
      investigation:,
      user:,
      date: nil,
      is_date_known: "false",
      severity:,
      usage:,
      investigation_product_id: investigation_product.id,
      type: "Accident",
      additional_info: nil
    ).accident_or_incident
  end

  describe ".build_metadata" do
    subject(:metadata) { described_class.build_metadata(accident_or_incident) }

    context "when fields have changed" do
      before { accident_or_incident.update!(severity: new_severity, date:, is_date_known: "yes", usage: new_usage, additional_info: "wow") }

      let(:updates) do
        {
          "severity" => [severity, new_severity],
          "usage" => [usage, new_usage],
          "additional_info" => [nil, "wow"],
          "is_date_known" => [false, true],
          "date" => [nil, date]
        }
      end

      it "builds a list of changes" do
        expect(metadata).to eq({
          updates:,
          type: accident_or_incident.type,
          accident_or_incident_id: accident_or_incident.id
        })
      end
    end
  end
end
