class FixIncorrectActivities < ActiveRecord::Migration[5.2]
  def up
    AuditActivity::Investigation::AddAllegation
      .where(created_at: 2.weeks.from_now)
      .find_each do |activity|
        AuditActivity::Investigation::AddAllegation.transaction do
          investigation = activitiy.investigation
          activitiy.destroy!
          activity = AuditActivity::Investigation::AddAllegation.from(investigation)
          activity.update!(created_at: investigation.created_at)
        end
      end

    AuditActivity::Investigation::AddEnquiry
      .where(created_at: 2.weeks.from_now)
      .find_each do |activity|
        AuditActivity::Investigation::AddEnquiry.transaction do
          investigation = activitiy.investigation
          activitiy.destroy!
          activity = AuditActivity::Investigation::AddEnquiry.from(investigation)
          activity.update!(created_at: investigation.created_at)
        end
      end

    AuditActivity::Investigation::AddProject
      .where(created_at: 2.weeks.from_now)
      .find_each do |activity|
        AuditActivity::Investigation::AddProject.transaction do
          investigation = activitiy.investigation
          activitiy.destroy!
          activity = AuditActivity::Investigation::AddProject.from(investigation)
          activity.update!(created_at: investigation.created_at)
        end
      end
  end

  def down
  end

end
