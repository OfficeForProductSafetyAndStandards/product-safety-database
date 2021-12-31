def create_log_db_metrics_job
  log_db_metrics_job = Sidekiq::Cron::Job.new(
    name: "#{ENV['SIDEKIQ_QUEUE'] || 'psd'}: log db metrics, every 15 minutes",
    cron: "*/15 * * * *",
    class: "LogDbMetricsJob",
    queue: ENV["SIDEKIQ_QUEUE"] || "psd"
  )
  unless log_db_metrics_job.save
    Rails.logger.error "***** WARNING - Log DB metrics job was not saved! *****"
    Rails.logger.error log_db_metrics_job.errors.join("; ")
  end
end

def create_lock_inactive_users_job
  lock_inactive_users_job = Sidekiq::Cron::Job.new(
    name: "#{ENV['SIDEKIQ_QUEUE'] || 'psd'}: lock inactive users, every day at 1am",
    cron: "0 1 * * *",
    class: "LockInactiveUsersJob",
    queue: ENV["SIDEKIQ_QUEUE"] || "psd"
  )
  unless lock_inactive_users_job.save
    Rails.logger.error "***** WARNING - Lock inactive users job was not saved! *****"
    Rails.logger.error lock_inactive_users_job.errors.join("; ")
  end
end

Sidekiq.configure_server do |config|
  config.redis = Rails.application.config_for(:redis_store)
  create_log_db_metrics_job
  create_lock_inactive_users_job
end

Sidekiq.configure_client do |config|
  config.redis = Rails.application.config_for(:redis_store)
end
