require "rails_helper"

RSpec.describe AddCorrectiveActionToCase, :with_stubbed_opensearch, :with_stubbed_mailer, :with_test_queue_adapter do
  subject(:result) { described_class.call(params) }

  include_context "with read only team and user"
  include_context "with add corrective action setup"

  let(:action) { action_key }
  let(:params) do
    corrective_action_form
      .serializable_hash
      .merge(
        investigation:,
        user:,
        changes: corrective_action_form.changes
      )
  end
  let(:expected_changes) do
    corrective_action_form.changes.tap do |c|
      c["date_decided"][1] = c["date_decided"][1].to_s
    end
  end

  def expected_email_body(user, user_with_edit_access)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{UserSource.new(user:)&.show(user_with_edit_access)}."
  end

  def expected_email_subject
    "#{investigation.case_type.upcase_first} updated"
  end

  it "creates the corrective action", :aggregate_failures do
    expect(result.corrective_action).not_to be_new_record
    expect(result.corrective_action)
      .to have_attributes(
        investigation:, date_decided:, business_id: business.id, details:, legislation:, measure_type:,
        duration:, geographic_scopes:, other_action:, action:, product_id: product.id,
        online_recall_information:, has_online_recall_information:
      )
  end

  it "creates and audit activity", :aggregate_failures do
    result

    audit = investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Add")
    expect(audit.source.user).to eq(user)

    expect(audit.metadata)
      .to eq("corrective_action" => result.corrective_action.as_json, "document" => result.corrective_action.document.attributes)
    expect(audit.business).to eq(business)
  end

  it_behaves_like "a service which notifies teams with access"
end
