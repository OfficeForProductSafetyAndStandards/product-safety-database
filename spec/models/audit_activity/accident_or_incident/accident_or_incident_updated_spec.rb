RSpec.describe AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated, :with_stubbed_mailer, :with_stubbed_antivirus do
  include ActionDispatch::TestProcess::FixtureFile

  let(:investigation) { create(:allegation, :with_products, creator: user) }
  let(:user) { create(:user) }
  let(:date) { Time.zone.today }
  let(:severity) { "high" }
  let(:new_severity) { "serious" }
  let(:usage) { "during_normal_use" }
  let(:new_usage) { "during_misuse" }
  let(:accident_or_incident) do
    AddAccidentOrIncidentToCase.call!(
      investigation:,
      user:,
      date: nil,
      is_date_known: "false",
      severity:,
      usage:,
      investigation_product_id: investigation.investigation_product_ids.first,
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

  describe "#metadata" do
    # TODO: remove once migrated
    context "when metadata contains a Product reference" do
      let(:investigation) { create(:allegation, :with_products) }
      let(:investigation_product) { investigation.investigation_products.first }
      let(:new_investigation_product) { create(:investigation_product, investigation:) }
      let(:activity) { described_class.new(investigation:, metadata: { updates: { product_id: [investigation_product.product_id, new_investigation_product.product_id] } }.deep_stringify_keys) }

      it "translates the Product ID to InvestigationProduct ID" do
        expect(activity.metadata["updates"]["product_id"]).to be_nil
        expect(activity.metadata["updates"]["investigation_product_id"]).to eq([investigation_product.id, new_investigation_product.id])
      end
    end
  end
end
