require "active_support/core_ext/integer/time"
require "cf-app-utils"
require "cgi"
require "json"
require "uri"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on AWS.
  config.active_storage.service = :amazon

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  config.ssl_options = {
    hsts: {
      subdomains: true,
      preload: true,
      expires: 2.years # (63072000 seconds)
    }
  }

  # Log to STDOUT by default
  if ENV["ENABLE_ASIM_LOGGER"] == "true"
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = Formatters::JsonFormatter.new
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  else
    config.logger = ActiveSupport::Logger.new($stdout)
      .tap  { |log| log.formatter = ::Logger::Formatter.new }
      .then { |log| ActiveSupport::TaggedLogging.new(log) }
  end

  # Prepend all log lines with the following tags.
  config.log_tags = %i[request_id]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  config.cache_store = :redis_cache_store, Rails.application.config_for(:redis_store)

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :sidekiq
  # config.active_job.queue_name_prefix = "product_safety_database_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.action_controller.default_url_options = {
    host: ENV["PSD_HOST"],
    protocol: "https"
  }

  config.action_mailer.default_url_options = {
    host: ENV["PSD_HOST"],
    protocol: "https"
  }

  # Connection setup (GOV PaaS)
  if ENV["VCAP_SERVICES"]
    opensearch_service = CF::App::Credentials.find_by_service_name("psd-opensearch-1")
    postgres_service = CF::App::Credentials.find_by_service_label("postgres")
    redis_service = CF::App::Credentials.find_by_service_label("redis")

    ENV["OPENSEARCH_URL"] = opensearch_service["uri"] if opensearch_service
    ENV["DATABASE_URL"] = postgres_service["uri"] if postgres_service
    ENV["REDIS_URL"] = redis_service["uri"] if redis_service

    # Set Redis URLs for session and queue services to support DBT platform migration
    ENV["SESSION_URL"] ||= CF::App::Credentials.find_by_service_name("psd-session-6")["uri"] if CF::App::Credentials.find_by_service_name("psd-session-6")
    ENV["QUEUE_URL"] ||= CF::App::Credentials.find_by_service_name("psd-queue-6")["uri"] if CF::App::Credentials.find_by_service_name("psd-queue-6")
  end

  # Connection setup (DBT Platform)
  if ENV["COPILOT_ENVIRONMENT_NAME"]
    if ENV["OPENSEARCH_URL"]
      ENV["OPENSEARCH_URL"] = URI.parse(CGI.unescape(ENV["OPENSEARCH_URL"]))
    end

    if ENV["DATABASE_CREDENTIALS"]
      database_credentials = JSON.parse(ENV["DATABASE_CREDENTIALS"])

      engine = database_credentials["engine"]
      username = database_credentials["username"]
      password = database_credentials["password"]
      host = database_credentials["host"]
      port = database_credentials["port"]
      dbname = database_credentials["dbname"]

      ENV["DATABASE_URL"] = "#{engine}://#{username}:#{password}@#{host}:#{port}/#{dbname}"
    end
  end
end
