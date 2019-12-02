ActionMailer::Base.add_delivery_method :govuk_notify, GovukNotifyRails::Delivery, api_key: Rails.application.config.govuk_api_key
