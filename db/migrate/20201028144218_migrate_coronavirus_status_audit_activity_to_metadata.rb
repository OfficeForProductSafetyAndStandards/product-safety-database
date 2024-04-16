class MigrateCoronavirusStatusAuditActivityToMetadata < ActiveRecord::Migration[6.0]
  def change
    AuditActivity::Investigation::UpdateCoronavirusStatus.all.find_each do |activity|
      next if activity.metadata

      new_status = !activity.attributes["body"].match?(/not related/)
      old_status = !new_status

      metadata = {
        updates: {
          "coronavirus_related" => [old_status, new_status]
        }
      }

      activity.update!(metadata:, body: nil, title: nil)
    end
  end
end
