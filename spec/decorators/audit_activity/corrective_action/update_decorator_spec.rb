require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::UpdateDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with corrective action setup for updates"

  subject(:decorated_activity) { corrective_action.reload.investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Update").decorate }

  let(:new_file_description)      { "new corrective action file description" }
  let(:new_filename)              { "corrective_action.txt" }
  let(:new_document)              { fixture_file_upload(file_fixture(new_filename)) }
  let(:corrective_action_form)    { CorrectiveActionForm.from(corrective_action) }
  let(:corrective_action_attributes) do
    corrective_action_form.tap { |form|
      form.assign_attributes(
        date_decided: new_date_decided,
        other_action: new_other_action,
        action: new_summary,
        product_id: corrective_action.product_id,
        measure_type: new_measure_type,
        legislation: new_legislation,
        has_online_recall_information: new_has_online_recall_information,
        online_recall_information: new_online_recall_information,
        geographic_scope: new_geographic_scope,
        duration: new_duration,
        details: new_details,
        business_id: corrective_action.business_id,
        existing_document_file_id: existing_document_file_id,
        related_file: true,
        file: file_form
      )
    }.serializable_hash
  end
  let(:changes) { corrective_action_form.changes }

  before do
    UpdateCorrectiveAction.call!(
      corrective_action_attributes
        .merge(corrective_action: corrective_action, user: user, changes: changes)
    )
  end

  it { expect(decorated_activity.new_action).to eq(CorrectiveAction.actions[new_summary]) }
  it { expect(decorated_activity.new_date_decided).to eq(new_date_decided.to_s(:govuk)) }

  describe "#new_online_recall_information" do
    context "when previously has online recall information was nil" do
      let(:has_online_recall_information) { nil }

      context "when new recall information is set" do
        specify do
          expect(decorated_activity.new_online_recall_information).to eq(new_online_recall_information)
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("No recall information published online")
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("Not relevant")
        end
      end
    end

    context "when previously has online recall information was yes" do
      let(:has_online_recall_information) { "has_online_recall_information_yes" }

      context "when new recall information is set" do
        let(:new_has_online_recall_information) { "has_online_recall_information_yes" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq(nil)
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("No recall information published online")
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }

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
          expect(decorated_activity.new_online_recall_information).to eq(new_online_recall_information)
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq(nil)
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }

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
          expect(decorated_activity.new_online_recall_information).to eq(new_online_recall_information)
        end
      end

      context "when new recall information is set to no" do
        let(:new_has_online_recall_information) { "has_online_recall_information_no" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq("No recall information published online")
        end
      end

      context "when new recall information is set to not relevant" do
        let(:new_has_online_recall_information) { "has_online_recall_information_not_relevant" }

        specify do
          expect(decorated_activity.new_online_recall_information).to eq(nil)
        end
      end
    end
  end

  it { expect(decorated_activity.new_legislation).to eq(new_legislation) }
  it { expect(decorated_activity.new_duration).to eq(new_duration) }
  it { expect(decorated_activity.new_details).to eq(new_details) }
  it { expect(decorated_activity.new_measure_type).to eq(new_measure_type) }
  it { expect(decorated_activity.new_geographic_scope).to eq(new_geographic_scope) }
  it { expect(decorated_activity.new_filename).to eq(File.basename(new_filename)) }
  it { expect(decorated_activity.new_file_description).to eq(new_file_description) }
end
