class FixIncorrectActivities < ActiveRecord::Migration[5.2]
  def up
    AuditActivity::Investigation::AddAllegation
      .where("created_at > ?", 2.weeks.ago)
      .find_each do |activity|
        AuditActivity::Investigation::AddAllegation.transaction do
          investigation = activity.investigation
          source = activity.source_id
          activity.destroy!
          AuditActivity::Investigation::AddAllegation.from(investigation)
          investigation
            .add_audit_activity
            .update_columns(
              created_at: investigation.created_at,
              source_id: source.id
            )
        end
      end

    AuditActivity::Investigation::AddEnquiry
      .where("created_at > ?", 2.weeks.ago)
      .find_each do |activity|
        AuditActivity::Investigation::AddEnquiry.transaction do
          investigation = activity.investigation
          source = activity.source_id
          activity.destroy!
          AuditActivity::Investigation::AddEnquiry.from(investigation)
          investigation
            .add_audit_activity
            .update_columns(
              created_at: investigation.created_at,
              source_id: source.id
            )
        end
      end

    AuditActivity::Investigation::AddProject
      .where("created_at > ?", 2.weeks.ago)
      .find_each do |activity|
        AuditActivity::Investigation::AddProject.transaction do
          investigation = activity.investigation
          source = activity.source_id
          activity.destroy!
          AuditActivity::Investigation::AddProject.from(investigation)
          investigation
            .add_audit_activity
            .update_columns(
              created_at: investigation.created_at,
              source_id: source.id
            )
        end
      end
  end

  def down
  end

end
