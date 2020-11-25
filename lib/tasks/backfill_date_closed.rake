namespace :investigations do
  desc "Backfill date_closed field"
  task backfill_date_closed: :environment do
    closed_investigations = Investigation.includes(:activities).where(is_closed: true, date_closed: nil)

    puts "Backfilling date closed for #{closed_investigations.count} closed investigations"

    closed_investigations.each do |investigation|
      closing_activity = investigation.activities.where(type: "AuditActivity::Investigation::UpdateStatus").order(created_at: :asc).last
      investigation.update!(date_closed: closing_activity.created_at) unless closing_activity.nil?
    end
  end
end
