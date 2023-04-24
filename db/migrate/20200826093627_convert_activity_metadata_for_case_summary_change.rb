class ConvertActivityMetadataForCaseSummaryChange < ActiveRecord::Migration[5.2]
  def up
    AuditActivity::Investigation::UpdateSummary.all.each do |activity|
      new_summary = activity.attributes["body"]

      # We need to construct the Hash manually because we can't retrospectively create ActiveRecord dirty models easily
      metadata = {
        updates: {
          "description" => [nil, new_summary]
        }
      }

      activity.update!(
        metadata:,
        body: nil,
        title: nil
      )
    end
  end

  def down
    AuditActivity::Investigation::UpdateSummary.all.each do |activity|
      activity.update!(
        metadata: nil,
        body: activity.metadata["updates"]["description"].second,
        title: "Case summary updated"
      )
    end
  end
end
