namespace :investigations do
  desc "Backfill date_closed field"
  task backfill_date_closed: :environment do
    closed_investigations = Investigation.includes(:activities).where(is_closed: true, date_closed: nil)

    puts "Backfilling date closed for #{closed_investigations.count} closed investigations"

    closed_investigations.each do |investigation|
      date_closed = investigation.activities.where(type: "AuditActivity::Investigation::UpdateStatus").last.created_at
      investigation.update(date_closed: date_closed)
    end
  end
end
