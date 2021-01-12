require "rails_helper"

RSpec.describe AddCorrectiveActionToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_test_queue_adapter do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  let(:action) { action_for_service }
  let(:params) do
    {
      investigation: investigation,
      user: user,
      date_decided: date_decided,
      business_id: business.id,
      details: details,
      legislation: legislation,
      measure_type: measure_type,
      duration: duration,
      geographic_scope: geographic_scope,
      other_action: other_action,
      action: action,
      product_id: product.id,
      online_recall_information: online_recall_information,
      has_online_recall_informationy: has_online_recall_information
    }
  end

  def expected_email_body(user, user_with_edit_access)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{UserSource.new(user: user)&.show(user_with_edit_access)}."
  end

  def expected_email_subject
    "Asdasd"
  end

  it_behaves_like "a service which notifies teams with access" do
    let(:result) { described_class.call(params) }
  end
end
