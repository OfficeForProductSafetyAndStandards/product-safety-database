require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Add, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:audit_activity) do
    create(
      :legacy_audit_add_activity_corrective_action,
      metadata:,
      investigation_product:,
      investigation: corrective_action.investigation,
      body:,
      title: legacy_title
    )
  end

  include_context "with read only team and user"
  include_context "with add corrective action setup"

  let(:metadata) { described_class.build_metadata(corrective_action) }
  let!(:corrective_action) do
    create(
      :corrective_action,
      action: action_key,
      other_action:,
      geographic_scope:,
      geographic_scopes:,
      investigation: notification,
      investigation_product:
    )
  end
  let(:legacy_title) { Faker::Hipster.sentence }
  let(:body) { nil }
  let(:geographic_scope) { nil }
  let(:geographic_scopes) { %i[great_britain northern_ireland] }

  describe ".migrate_geographic_scopes" do
    let(:geographic_scope) { Rails.application.config.corrective_action_constants["geographic_scope"].sample }
    let(:geographic_scopes) { nil }

    it "migrates the data" do
      expect { described_class.migrate_geographic_scopes!(audit_activity) }
        .to change { audit_activity.reload.metadata.dig("corrective_action", "geographic_scopes") }
              .from(nil)
              .to(CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[geographic_scope])
    end
  end

  describe ".metadata_from_legacy_audit_activity" do
    let(:metadata) { nil }
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

    context "when no document was attached" do
      context "when notification does not have an audit for an updated corrective action" do
        context "when notification as only audit for an added corrective action" do
          it "retrieves the corrective action by the update" do
            expect(described_class.metadata_from_legacy_audit_activity(audit_activity)[:corrective_action][:id])
              .to eq(corrective_action.id)
          end
        end

        context "when the corrective_action has more than one corrective action" do
          let(:other_corrective_action) { create(:corrective_action, :with_document, investigation: corrective_action.investigation) }

          before do
            create(:legacy_audit_add_activity_corrective_action, investigation: corrective_action.investigation).attachment.attach(other_corrective_action.document_blob)
            corrective_action.investigation.reload
          end

          context "when one has an attachment" do
            it "returns the corrective action that has no attachment" do
              expect(described_class.metadata_from_legacy_audit_activity(audit_activity)[:corrective_action][:id])
                .to eq(corrective_action.id)
            end
          end

          context "when sevaral do not have no attachment" do
            before do
              create(:corrective_action, investigation: corrective_action.investigation)
              create(:legacy_audit_add_activity_corrective_action, investigation: corrective_action.investigation)
              corrective_action.investigation.reload
            end

            it "returns raise and error" do
              expect { described_class.metadata_from_legacy_audit_activity(audit_activity) }
                .to raise_error AuditActivity::CorrectiveAction::CouldNotDeterminCorrectiveAction
            end
          end
        end
      end
    end

    it "migrates all attributes to the new metadata format" do
      expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
        .to eq(corrective_action: {
          legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: details.strip, id: corrective_action.id
        })
    end

    context "when missing parts" do
      context "when missing legislation" do
        let(:legislation_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: corrective_action.legislation, date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: details.strip, id: corrective_action.id
            })
        end
      end

      context "when missing date decided" do
        let(:date_decided_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: corrective_action.date_decided, measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: details.strip, id: corrective_action.id
            })
        end
      end

      context "when missing measure type" do
        let(:measure_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: corrective_action.measure_type, duration: "Unknown", geographic_scope: "Local", details: details.strip, id: corrective_action.id
            })
        end
      end

      context "when missing duration" do
        let(:duration_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: corrective_action.duration, geographic_scope: "Local", details: details.strip, id: corrective_action.id
            })
        end
      end

      context "when missing geographic scope" do
        let(:geographic_scope_string) { nil }

        it "fetches from the corrective_action" do
          expect(described_class.metadata_from_legacy_audit_activity(audit_activity))
            .to eq(corrective_action: {
              legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: corrective_action.geographic_scope, details: details.strip, id: corrective_action.id
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
            legislation: "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)", date_decided: Date.parse("01/11/2010"), measure_type: "Voluntary", duration: "Unknown", geographic_scope: "Local", details: nil, id: corrective_action.id
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

  describe "#metadata" do
    # TODO: remove once migrated
    context "when metadata contains a Product reference" do
      let(:metadata) do
        data = described_class.build_metadata(corrective_action).stringify_keys
        data["corrective_action"]["product_id"] = notification.product_ids.first
        data["corrective_action"].delete("investigation_product_id")
        data
      end

      it "translates the Product ID to InvestigationProduct ID" do
        expect(audit_activity.metadata["corrective_action"]["product_id"]).to be_nil
        expect(audit_activity.metadata["corrective_action"]["investigation_product_id"]).to eq(notification.investigation_product_ids.first)
      end
    end
  end
end
