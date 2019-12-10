class FixIncorrectActivities < ActiveRecord::Migration[5.2]

  def update_activity(investigation, user)
    activity = investigation.reload.add_audit_activity
    activity.update_column(:created_at, investigation.created_at)
    UserSource.create!(user: user, sourceable: activity)
  end

  def up
    AuditActivity::Investigation::AddAllegation
      .where("created_at > ?", 2.weeks.ago)
      .find_each do |activity|
        AuditActivity::Investigation::AddAllegation.transaction do
          investigation = activity.investigation
          user = activity.source.user
          activity.destroy!
          AuditActivity::Investigation::AddAllegation.from(investigation)
          update_activity(investigation, user)
        end
      end

    AuditActivity::Investigation::AddEnquiry
      .where("created_at > ?", 2.weeks.ago)
      .find_each do |activity|
        AuditActivity::Investigation::AddEnquiry.transaction do
          investigation = activity.investigation
          user = activity.source.user
          activity.destroy!
          AuditActivity::Investigation::AddEnquiry.from(investigation)
          update_activity(investigation, user)
        end
      end

    AuditActivity::Investigation::AddProject
      .where("created_at > ?", 2.weeks.ago)
      .find_each do |activity|
        AuditActivity::Investigation::AddProject.transaction do
          investigation = activity.investigation
          user = activity.source.user
          activity.destroy!
          AuditActivity::Investigation::AddProject.from(investigation)
          activity = investigation.reload.add_audit_activity
          update_activity(investigation, user)
        end
      end
  end

  def down
  end

end
