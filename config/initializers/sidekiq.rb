def remove_files_without_attachments_job
  remove_files_without_attachments_job = Sidekiq::Cron::Job.new(
    name: "#{ENV['SIDEKIQ_QUEUE'] || 'psd'}: remove files not attached to anything, midnight every sunday",
    cron: "0 0 * * 0",
    class: "RemoveFilesWithoutAttachmentsJob",
    queue: ENV["SIDEKIQ_QUEUE"] || "psd"
  )
  unless remove_files_without_attachments_job.save
    Rails.logger.error "***** WARNING - Removing files without attachments was not saved! *****"
    Rails.logger.error remove_files_without_attachments_job.errors.join("; ")
  end
end

def create_log_db_metrics_job
  log_db_metrics_job = Sidekiq::Cron::Job.new(
    name: "#{ENV['SIDEKIQ_QUEUE'] || 'psd'}: log db metrics, every day at 1am",
    cron: "0 1 * * *",
    class: "LogDbMetricsJob",
    queue: ENV["SIDEKIQ_QUEUE"] || "psd"
  )
  unless log_db_metrics_job.save
    Rails.logger.error "***** WARNING - Log DB metrics job was not saved! *****"
    Rails.logger.error log_db_metrics_job.errors.join("; ")
  end
end

Sidekiq.configure_server do |config|
  config.redis = Rails.application.config_for(:redis_store)
  remove_files_without_attachments_job
  create_log_db_metrics_job
end

Sidekiq.configure_client do |config|
  config.redis = Rails.application.config_for(:redis_store)
end
