require "rails_helper"

RSpec.describe AddCorrectiveActionToNotification, :with_stubbed_mailer, :with_test_queue_adapter do
  subject(:result) { described_class.call(params) }

  include_context "with read only team and user"
  include_context "with add corrective action setup"

  let(:action) { action_key }
  let(:params) do
    corrective_action_form
      .serializable_hash
      .merge(
        notification:,
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
    "Corrective action was added to the notification by #{user&.decorate&.display_name(viewer: user_with_edit_access)}."
  end

  def expected_email_subject
    "Notification updated"
  end

  it "creates the corrective action", :aggregate_failures do
    expect(result.corrective_action).not_to be_new_record
    expect(result.corrective_action)
      .to have_attributes(
        investigation: notification, date_decided:, business_id: business.id, details:, legislation:, measure_type:,
        duration:, geographic_scopes:, other_action:, action:, investigation_product_id: investigation_product.id,
        online_recall_information:, has_online_recall_information:
      )
  end

  it "creates and audit activity", :aggregate_failures do
    result

    audit = notification.activities.find_by!(type: "AuditActivity::CorrectiveAction::Add")
    expect(audit.added_by_user).to eq(user)

    expect(audit.metadata)
      .to eq("corrective_action" => result.corrective_action.as_json, "document" => result.corrective_action.document.attributes)
    expect(audit.business).to eq(business)
  end

  it "does not add OPSS IMT with edit permissions as a collaborator" do
    expect(result.notification.teams_with_edit_access).to eq([user.team])
  end

  it_behaves_like "a service which notifies teams with access"

  context "when the notification risk level is serious" do
    let(:opss_imt) { create(:team, name: "OPSS Incident Management") }

    before do
      opss_imt
      notification.risk_level = "serious"
      notification.save!
    end

    it "adds OPSS IMT with edit permissions as a collaborator" do
      expect(result.notification.teams_with_edit_access).to contain_exactly(user.team, opss_imt)
    end
  end

  context "when the corrective action indicates a recall" do
    let(:action_key) { "recall_of_the_product_from_end_users" }
    let(:opss_imt) { create(:team, name: "OPSS Incident Management") }

    before do
      opss_imt
      notification.risk_level = "low"
      notification.save!
    end

    it "adds OPSS IMT with edit permissions as a collaborator" do
      expect(result.notification.teams_with_edit_access).to contain_exactly(user.team, opss_imt)
    end
  end
end
