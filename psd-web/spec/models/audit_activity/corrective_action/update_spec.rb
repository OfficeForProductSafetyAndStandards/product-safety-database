require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Update, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include_context "with corrective action setup for updates"

  describe ".build_metadata" do
    let!(:old_attchment) { corrective_action.documents.first }

    before do
      corrective_action.update!(
        summary: new_summary,
        date_decided_day: new_date_decided.day,
        date_decided_month: new_date_decided.month,
        date_decided_year: new_date_decided.year,
        product: product_two,
        legislation: new_legislation,
        business: business_two,
        geographic_scope: new_geographic_scope,
        details: new_details,
        measure_type: new_measure_type,
        duration: new_duration
      )
    end

    it "has all the updated metadata" do
      expect(described_class.build_metadata(corrective_action, old_attchment))
        .to eq(corrective_action_id: corrective_action.id, updates: corrective_action.previous_changes)
    end
  end
end
