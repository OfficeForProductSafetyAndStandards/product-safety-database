# Be sure to restart your server when you modify this file.
# Setup Sentry (from https://github.com/getsentry/raven-ruby/blob/master/examples/rails-5.0/config/application.rb)

Rails.application.configure do
  config.rails_activesupport_breadcrumbs = true

  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.send_default_pii = false
    config.breadcrumbs_logger << :sentry_logger
    config.excluded_exceptions += ["Pundit::NotAuthorizedError"]
    config.capture_exception_frame_locals = true
  end
end
