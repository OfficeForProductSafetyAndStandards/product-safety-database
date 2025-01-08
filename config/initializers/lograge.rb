# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.lograge.enabled = ENV.fetch("LOGRAGE_ENABLED", "true") == "true"

  config.lograge.custom_payload do |controller|
    extra_payload = {}
    user_id = controller.current_user&.id
    extra_payload[:user_id] = user_id if user_id
    organisation_id = controller.current_user&.organisation&.id
    extra_payload[:organisation_id] = organisation_id if organisation_id
    extra_payload
  end
end
