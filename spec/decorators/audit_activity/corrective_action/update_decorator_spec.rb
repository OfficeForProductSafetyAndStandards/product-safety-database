require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::UpdateDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with corrective action setup for updates"

  subject(:decorated_activity) { corrective_action.reload.investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Update").decorate }

  let(:new_file_description)      { "new corrective action file description" }
  let(:new_filename)              { "files/corrective_action.txt" }
  let(:new_document)              { ActiveStorage::Blob.create_after_upload!(io: fixture_file_upload(file_fixture(new_filename)), filename: new_filename, content_type: "plain/text") }
  let(:corrective_action_form)    { CorrectiveActionForm.from(corrective_action) }
  let(:corrective_action_attributes) do
    corrective_action_form.tap { |form|
      form.assign_attributes(
        date_decided: new_date_decided,
        other_action: new_other_action,
        action: new_action,
        product_id: corrective_action.product_id,
        measure_type: new_measure_type,
        legislation: new_legislation,
        has_online_recall_information: new_has_online_recall_information,
        geographic_scope: new_geographic_scope,
        duration: new_duration,
        details: new_details,
        business_id: corrective_action.business_id,
        existing_document_file_id: existing_document_file_id,
        related_file: related_file,
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
  it { expect(decorated_activity.new_legislation).to eq(new_legislation) }
  it { expect(decorated_activity.new_duration).to eq(new_duration) }
  it { expect(decorated_activity.new_details).to eq(new_details) }
  it { expect(decorated_activity.new_measure_type).to eq(new_measure_type) }
  it { expect(decorated_activity.new_geographic_scope).to eq(new_geographic_scope) }
  it { expect(decorated_activity.new_filename).to eq(File.basename(new_filename)) }
  it { expect(decorated_activity.new_file_description).to eq(new_file_description) }
end
