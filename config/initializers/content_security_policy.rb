# Be sure to restart your server when you modify this file.

# govuk_domains = [
#   "*.london.cloudapps.digital", # For preview apps
#   "*.service.gov.uk",
# ].freeze
# google_analytics_domains = %w[www.google-analytics.com
#                               ssl.google-analytics.com
#                               stats.g.doubleclick.net
#                               www.googletagmanager.com
#                               www.region1.google-analytics.com
#                               region1.google-analytics.com]
# google_static_domains = %w[www.gstatic.com]

trusted_script_sources = [:self, "https://www.googletagmanager.com"]
trusted_style_sources  = [:self, "https://fonts.googleapis.com"]
trusted_font_sources = [:self, "https://fonts.gstatic.com", "*.gov.uk"]
trusted_img_sources = %i[self data]

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.object_src :none
  policy.child_src :self
  policy.frame_ancestors :none
  policy.upgrade_insecure_requests true
  policy.block_all_mixed_content true
  policy.script_src(*trusted_script_sources)
  policy.style_src(*trusted_style_sources)
  policy.font_src(*trusted_font_sources)
  policy.img_src(*trusted_img_sources)
end

# Enable CSP nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src style-src]
