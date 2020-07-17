require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Update, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include_context "with corrective action setup for updates"

  describe ".build_metadata" do
    let!(:old_attachment)  { corrective_action.documents.first }
    let!(:old_description) { old_attachment.metadata[:description] }
    let!(:old_filename)    { old_attachment.filename }
    let(:new_description)  { "new description" }
    let!(:new_filename)    { "new_filename" }

    before do
      old_attachment.blob.metadata[:description] = new_description
      old_attachment.filename = new_filename
      old_attachment.blob.save!
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
      expect(described_class.build_metadata(corrective_action, old_attachment))
        .to eq(corrective_action_id: corrective_action.id,
               updates: corrective_action.previous_changes.merge(
                 file_description: [old_description, new_description],
                 filename: [old_filename.to_s, new_filename]
               )
              )
    end
  end
end
