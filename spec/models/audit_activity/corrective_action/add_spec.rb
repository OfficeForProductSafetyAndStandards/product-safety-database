require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Add, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  subject(:audit_activity) { described_class.new(metadata: metadata, product: product) }

  let(:metadata) { described_class.build_metadata(corrective_action) }
  let!(:corrective_action) { create(:corrective_action, action: action_key, other_action: other_action) }

  describe ".migrate_legacy_audit_activity" do
    let(:details) do
      "balbabl alf ba;erl qmer


ergq perog n


 gerg erg"
    end
    let(:body) do
      "Product: **qerg qerg qerg q**<br>Legislation: **Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)**<br>Date came into effect: **01/11/2010**<br>Type of measure: **Voluntary**<br>Duration of action: **Unknown**<br>Geographic scopes: **Local, EEA Wide and EU Wide**<br>Attached: **c07ff66d5b.jpg**<br>" + details
    end
    let(:audit_activity) { described_class.new(body: body, title: "Marketing conditions:  qerg qerg qerg q") }

    it "migrates all attributes to the new metadata format" do
      expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
        .to eq(corrective_action: {
          legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", decided_date: Date.parse("01/11/2010"), measure: "Voluntary", duration: "Unknown", geographic_scopes: "Local, EEA Wide and EU Wide", details: details.strip
        })
    end

    context "with an empty lines in the details field" do
      let(:details) do
        "


        "
      end

      it "trims details" do
        expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
          .to eq(corrective_action: {
            legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", decided_date: Date.parse("01/11/2010"), measure: "Voluntary", duration: "Unknown", geographic_scopes: "Local, EEA Wide and EU Wide", details: nil
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
