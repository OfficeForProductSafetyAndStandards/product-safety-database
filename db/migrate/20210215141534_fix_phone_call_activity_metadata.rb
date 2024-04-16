class FixPhoneCallActivityMetadata < ActiveRecord::Migration[6.1]
  def up
    AuditActivity::Correspondence::AddPhoneCall.includes(:correspondence).all.find_each do |activity|
      new_metadata = AuditActivity::Correspondence::AddPhoneCall.build_metadata(activity.correspondence)
      activity.metadata = new_metadata
      activity.save!
    end
  end

  def down
    AuditActivity::Correspondence::AddPhoneCall.update_all metadata: {}
  end
end
