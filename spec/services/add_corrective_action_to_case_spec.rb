require "rails_helper"

RSpec.describe AddCorrectiveActionToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_test_queue_adapter do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  subject(:result) { described_class.call(params) }

  let(:action) { action_for_service }
  let(:params) do
    corrective_action_form
      .serializable_hash
      .merge(
        investigation: investigation,
        user: user,
        changes: corrective_action_form.changes
      )
  end
  let(:expected_changes) do
    corrective_action_form.changes.tap do |c|
      c["date_decided"][1] = c["date_decided"][1].to_s
    end
  end

  def expected_email_body(user, user_with_edit_access)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{UserSource.new(user: user)&.show(user_with_edit_access)}."
  end

  def expected_email_subject
    "#{investigation.case_type.upcase_first} updated"
  end

  it "creates the corrective action", :aggregate_failures do
    expect(result.corrective_action).not_to be_new_record
    expect(result.corrective_action)
      .to have_attributes(
        investigation: investigation, date_decided: date_decided, business_id: business.id, details: details, legislation: legislation, measure_type: measure_type,
        duration: duration, geographic_scope: geographic_scope, other_action: other_action, action: action, product_id: product.id,
        online_recall_information: online_recall_information, has_online_recall_information: has_online_recall_information
      )
  end

  it "creates and audit activity", :aggregate_failures do
    result

    audit = investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Add")
    expect(audit.source.user).to eq(user)

    expect(audit.metadata).to eq(
      "corrective_action_id" => result.corrective_action.id, "updates" => expected_changes
    )
    expect(audit.business).to eq(business)
  end

  it_behaves_like "a service which notifies teams with access"
end
