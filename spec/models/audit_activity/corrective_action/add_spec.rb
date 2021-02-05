require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Add, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  subject(:audit_activity) do
    create(
      :legacy_audit_add_activity_corrective_action,
      metadata: metadata,
      product: product,
      investigation: corrective_action.investigation,
      body: body
    )
  end

  let(:metadata) { described_class.build_metadata(corrective_action) }
  let!(:corrective_action) { create(:corrective_action, action: action_key, other_action: other_action) }
  let(:body) { nil }

  describe ".migrate_legacy_audit_activity" do
    let(:details_string) do
      "balbabl alf ba;erl qmer

ergq perog n

"
    end
    let(:legislation_string)      { "Legislation: **Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)**" }
    let(:date_decided_string)     { "Date came into effect: **01/11/2010**" }
    let(:measure_string)          { "Type of measure: **Voluntary**" }
    let(:duration_string)         { "Duration of action: **Unknown**" }
    let(:geographic_scope_string) { "Geographic scope: **Local**" }
    let(:body) do
      "Product: **qerg qerg qerg q**<br>#{legislation_string}<br>#{date_decided_string}<br>#{measure_string}<br>#{duration_string}<br>#{geographic_scope_string}<br>Attached: **c07ff66d5b.jpg**<br>" + details
    end

    it "migrates all attributes to the new metadata format" do
      expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
        .to eq(corrective_action: {
          legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: details.strip
        })
    end

    context "when missing parts" do
      context "when missing legislation" do
        let(:legislation_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: corrective_action.legislation, date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: details.strip
            })
        end
      end

      context "when missing date decided" do
        let(:date_decided_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: corrective_action.date_decided, measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: details.strip
            })
        end
      end

      context "when missing measure type" do
        let(:measure_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: corrective_action.measure_type, duration: "Unknown", geographic_scope: "Local", details: details.strip
            })
        end
      end

      context "when missing duration" do
        let(:duration_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: corrective_action.duration, geographic_scope: "Local", details: details.strip
            })
        end
      end

      context "when missing geographic scope" do
        let(:geographic_scope_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: corrective_action.geographic_scope, details: details.strip
            })
        end
      end
    end

    context "with an empty lines in the details field" do
      let(:details) do
        "


        "
      end

      it "trims details" do
        expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
          .to eq(corrective_action: {
            legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: nil
          })
      end
    end
  end

  describe ".build_metadata" do
    context "with no document attached" do
      it "saves the passed changes and corrective action id" do
        expect(described_class.build_metadata(corrective_action))
          .to eq(corrective_action: corrective_action.attributes, document: nil)
      end
    end

    context "with a document attached" do
      let!(:corrective_action) { create(:corrective_action, :with_document) }

      it "saves the passed changes and corrective action id" do
        expect(described_class.build_metadata(corrective_action))
          .to eq(corrective_action: corrective_action.attributes, document: corrective_action.document_blob.attributes)
      end
    end
  end

  describe "#title" do
    let(:expected_title) { "#{CorrectiveAction::TRUNCATED_ACTION_MAP[action_key.to_sym]}: #{product.name}" }

    context "when the action is not other" do
      it "shows the action and product name" do
        expect(audit_activity.title).to eq(expected_title)
      end
    end

    context "when the action is set to other" do
      let(:action_key) { "other" }
      let(:other_action) { Faker::Hipster.sentence }

      it "shows the action and product name" do
        expect(audit_activity.title).to eq(other_action)
      end
    end
  end
end
