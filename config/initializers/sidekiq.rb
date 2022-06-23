Sidekiq.configure_server do |config|
  config.redis = Rails.application.config_for(:redis_store)
end

Sidekiq.configure_client do |config|
  config.redis = Rails.application.config_for(:redis_store)
end
