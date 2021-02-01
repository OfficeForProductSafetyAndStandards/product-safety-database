require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Base, :with_stubbed_elasticsearch, :with_stubbed_antivirus do
  include_context "with corrective action setup for updates"

  subject(:activity) { described_class.last }

  let!(:corrective_action)        { create(:corrective_action, :with_file, investigation: investigation, product: product, business: business) }
  let(:corrective_action_form)    { CorrectiveActionForm.from(corrective_action) }

  before do
    corrective_action_form.date_decided = new_date_decided
    corrective_action_form.related_file = true
    UpdateCorrectiveAction.call!(
      corrective_action_form
        .serializable_hash
        .merge(corrective_action: corrective_action, user: user, changes: corrective_action_form.changes)
    )
  end

  describe "#corrective_action" do
    subject(:activity) { create :legacy_audit_activity_corrective_action }

    context "with backward compatibilty, looking up by attachment" do
      context "with no attachment" do
        it "returns nil" do
          expect(activity.corrective_action).to eq(nil)
        end
      end

      context "with attachment" do
        before { activity.attachment.attach corrective_action.document_blob }

        it "finds the corrective corrective action" do
          expect(activity.corrective_action).to eq(corrective_action)
        end
      end
    end
  end
end
