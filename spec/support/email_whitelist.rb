def set_whitelisting_enabled(enabled)
  allow(Rails.application.config).to receive(:email_whitelist_enabled).and_return(enabled)
end
