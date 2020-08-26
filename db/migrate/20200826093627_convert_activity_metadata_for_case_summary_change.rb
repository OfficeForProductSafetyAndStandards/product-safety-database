class ConvertActivityMetadataForCaseSummaryChange < ActiveRecord::Migration[5.2]
  def up
    AuditActivity::Investigation::UpdateSummary.all.each do |activity|
      new_summary = activity.attributes["body"]

      activity.update!(
        metadata: activity.class.build_metadata(new_summary, nil),
        body: nil,
        title: nil
      )
    end
  end

  def down
    AuditActivity::Investigation::UpdateSummary.all.each do |activity|
      activity.update!(
        metadata: nil,
        body: activity.metadata["summary"]["new"],
        title: "#{activity.investigation.case_type.upcase_first} summary updated"
      )
    end
  end
end
