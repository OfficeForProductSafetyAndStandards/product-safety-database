require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Update, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with corrective action setup for updates"

  describe ".build_metadata" do
    let!(:old_attachment)  { corrective_action.documents.first }
    let!(:old_description) { old_attachment.metadata[:description] }
    let!(:old_filename)    { old_attachment.filename }
    let(:new_description)  { "new description" }
    let(:expected_corrective_action_changes) do
      corrective_action
        .previous_changes
        .except(:date_decided_day, :date_decided_month, :date_decided_year, :related_file)
    end

    before do
      old_attachment.blob.metadata[:description] = old_description
      old_attachment.blob.metadata[:filename] = old_attachment.filename
      old_attachment.blob.save!
      corrective_action.update!(
        action: new_summary,
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

      corrective_action.documents.detach
      new_blob = corrective_action.documents.attach(new_file).first.blob
      new_blob.metadata[:description] = new_description
      new_blob.metadata[:filename] = new_blob.filename
      new_blob.save!
    end

    it "has all the updated metadata" do
      expect(described_class.build_metadata(corrective_action, old_attachment))
        .to eq(corrective_action_id: corrective_action.id,
               updates: expected_corrective_action_changes.merge(
                 file_description: [old_description, new_description],
                 filename: [old_filename.to_s, corrective_action.documents.first.filename.to_s]
               ))
    end
  end
end
