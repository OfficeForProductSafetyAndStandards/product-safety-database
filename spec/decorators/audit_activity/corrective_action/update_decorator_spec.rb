RSpec.describe AuditActivity::CorrectiveAction::UpdateDecorator, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:decorated_activity) { corrective_action.reload.investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Update").decorate }

  include_context "with corrective action setup for updates"

  let(:new_file_description)      { "new corrective action file description" }
  let(:new_filename)              { "corrective_action.txt" }
  let(:new_document)              { fixture_file_upload(file_fixture(new_filename)) }
  let(:corrective_action_form)    { CorrectiveActionForm.from(corrective_action) }
  let(:corrective_action_attributes) do
    corrective_action_form.tap { |form|
      form.tap(&:valid?).assign_attributes(
        date_decided: new_date_decided,
        other_action: new_other_action,
        action: new_summary,
        investigation_product_id: corrective_action.investigation_product_id,
        measure_type: new_measure_type,
        legislation: new_legislation,
        has_online_recall_information: new_has_online_recall_information,
        online_recall_information: new_online_recall_information,
        geographic_scopes: new_geographic_scopes,
        duration: new_duration,
        details: new_details,
        business_id: corrective_action.business_id,
        existing_document_file_id:,
        related_file: true,
        file: file_form
      )
    }.serializable_hash
  end
  let(:changes) { corrective_action_form.changes }

  before do
    UpdateCorrectiveAction.call!(
      corrective_action_attributes
        .merge(corrective_action:, user:, changes:)
    )
  end

  describe "#new_action" do
    context "when action is other" do
      let(:new_summary) { "other" }

      it "returns the other action description" do
        expect(decorated_activity.new_action).to eq(new_other_action)
      end
    end

    context "when action is not other" do
      it "returns the action name" do
        expect(decorated_activity.new_action).to eq(CorrectiveAction.actions[new_summary])
      end
    end
  end

  it { expect(decorated_activity.new_date_decided).to eq(new_date_decided.to_formatted_s(:govuk)) }

  describe "#new_online_recall_information" do
    context "when previously has online recall information was nil" do
      let(:has_online_recall_information) { nil }

      context "when new recall information is set" do
        context "when new recall info is a valid url" do
          it "displays new online recall info" do
            expect(decorated_activity.new_online_recall_information).to match(new_online_recall_information)
          end

          it "displays a link to the online recall info" do
            expect(decorated_activity.new_online_recall_information).to match(/href/)
          end
        end

        context "when new recall info is not a valid url" do
          let(:new_online_recall_information) { "not a URL" }

          it "displays new online recall info" do
            expect(decorated_activity.new_online_recall_information).to match(new_online_recall_information)
          end

          it "does not display a link to the online recall info" do
            expect(decorated_activity.new_online_recall_information).not_to match(/href/)
          end
        end
      end

      context "when new recall information is set to no" do
        let(:new_online_recall_information) { "" }
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not published online")
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not relevant")
        end
      end
    end

    context "when previously has online recall information was yes" do
      let(:has_online_recall_information) { "has_online_recall_information_yes" }

      context "when new recall information is set" do
        let(:new_has_online_recall_information) { "has_online_recall_information_yes" }

        context "when the recall information does not change" do
          let(:new_online_recall_information) { corrective_action.online_recall_information }

          specify do
            expect(decorated_activity.new_online_recall_information).to eq(nil)
          end
        end

        context "when the recall information changes" do
          specify do
            expect(decorated_activity.new_online_recall_information).to match(new_online_recall_information)
          end
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not published online")
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not relevant")
        end
      end
    end

    context "when previously has online recall information was no" do
      let(:has_online_recall_information) { "has_online_recall_information_no" }

      context "when new recall information is set" do
        let(:new_has_online_recall_information) { "has_online_recall_information_yes" }

        specify do
          expect(decorated_activity.new_online_recall_information).to match(new_online_recall_information)
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq(nil)
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not relevant")
        end
      end
    end

    context "when previously has online recall information was not relevant" do
      let(:has_online_recall_information) { "has_online_recall_information_not_relevant" }

      context "when new recall information is set" do
        let(:new_has_online_recall_information) { "has_online_recall_information_yes" }

        specify do
          expect(decorated_activity.new_online_recall_information).to match(new_online_recall_information)
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not published online")
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }
        let(:new_online_recall_information) { "" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq(nil)
        end
      end
    end
  end

  describe "#file_description_changed?" do
    before { decorated_activity.object.update!(metadata: updates) }

    context "when file description changed" do
      let(:updates) { { updates: { file_description: ["old description", "new description"] } } }

      it { is_expected.to be_file_description_changed }
    end

    context "when file description did not changed" do
      let(:updates) { { updates: {} } }

      it { is_expected.not_to be_file_description_changed }
    end
  end

  it { expect(decorated_activity.new_legislation).to eq(new_legislation) }
  it { expect(decorated_activity.new_duration).to eq(new_duration) }
  it { expect(decorated_activity.new_details).to eq(new_details) }
  it { expect(decorated_activity.new_measure_type).to eq(new_measure_type) }
  it { expect(decorated_activity.new_geographic_scopes).to eq(new_geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }.to_sentence) }
  it { expect(decorated_activity.new_filename).to eq(File.basename(new_filename)) }
  it { expect(decorated_activity.new_file_description).to eq(new_file_description) }

  describe "#attachment and #attached_image" do
    context "with an existing document id metadata" do
      let(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: document,
          filename: Faker::Hipster.word,
          content_type: "text/plain",
          metadata: {}
        )
      end
      let(:changes) { corrective_action.previous_changes.merge(existing_document_file_id: [nil, blob.signed_id]) }

      context "when the document is not an image" do
        let(:document) { fixture_file_upload("corrective_action.txt") }

        it "returns the saved record in the update metadata", :aggregate_failures do
          expect(decorated_activity.attachment).to eq(blob)
          expect(decorated_activity).not_to be_attached_image
        end
      end

      context "when the document is an image" do
        let(:document) { fixture_file_upload("testImage.png") }

        it "returns the saved record in the update metadata", :aggregate_failures do
          expect(decorated_activity.attachment).to eq(blob)
          expect(decorated_activity).to be_attached_image
        end
      end
    end
  end
end
