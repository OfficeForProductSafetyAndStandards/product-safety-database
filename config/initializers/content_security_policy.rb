# Be sure to restart your server when you modify this file.

# Trusted sources
trusted_script_sources = [:self, "https://www.googletagmanager.com"]
trusted_style_sources = [:self, "https://fonts.googleapis.com"]
trusted_font_sources = [:self, "https://fonts.gstatic.com", "*.gov.uk"]
trusted_img_sources = %i[self data]
trusted_connect_sources = [:self,
                           "https://*.google-analytics.com",
                           "https://stats.g.doubleclick.net"]

# Configuration
Rails.application.config.content_security_policy do |policy|
  # Core security directives
  policy.default_src :self
  policy.object_src :none
  policy.child_src :self
  policy.frame_ancestors :none
  policy.upgrade_insecure_requests true
  policy.block_all_mixed_content true

  # Script handling with nonce support
  nonce_only = ->(request) { "'nonce-#{request.content_security_policy_nonce}'" }

  # Script directives for modules & webpack support
  policy.script_src(*trusted_script_sources, :unsafe_eval, &nonce_only)
  policy.script_src_elem(*trusted_script_sources, :unsafe_eval, &nonce_only)
  policy.script_src_attr(*trusted_script_sources)

  # Style directive configured for inline styles
  policy.style_src(*trusted_style_sources, :unsafe_hashes, "unsafe-inline")

  # Additional resource directives
  policy.font_src(*trusted_font_sources)
  policy.img_src(*trusted_img_sources)

  # Connect-src directive for Google Analytics
  policy.connect_src(*trusted_connect_sources)
end

# CSP nonce configuration
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src script-src-elem]
