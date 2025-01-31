namespace :investigations do
  desc "Update submitted_at with created_at for investigations where submitted_at is nil"
  task update_submitted_date: :environment do
    Investigation.unscoped.where(submitted_at: nil).find_each(batch_size: 500) do |investigation|
      investigation.update_columns(submitted_at: investigation.created_at)
    end
  end
end
