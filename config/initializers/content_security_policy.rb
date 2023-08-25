govuk_domains = [
  "*.london.cloudapps.digital", # For preview apps
  "*.service.gov.uk",
].freeze
google_analytics_domains = %w[www.google-analytics.com
                              ssl.google-analytics.com
                              stats.g.doubleclick.net
                              www.googletagmanager.com
                              www.region1.google-analytics.com
                              region1.google-analytics.com]
google_static_domains = %w[www.gstatic.com]

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/base-uri
    policy.base_uri :none

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/img-src
    # Note: we purposely don't include `data:` here because it produces a security risk.
    policy.img_src :self,
                   *govuk_domains,
                   *google_analytics_domains # Tracking pixels

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src
    # Note: we purposely don't include `data:`, `unsafe-inline` or `unsafe-eval` because
    # they are security risks, if you need them for a legacy app please only apply them at
    # an app level.
    policy.script_src :self,
                      *google_analytics_domains,
                      *google_static_domains

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/style-src
    # Note: we purposely don't include `data:`, `unsafe-inline` or `unsafe-eval` because
    # they are security risks, if you need them for a legacy app please only apply them at
    # an app level.
    policy.style_src :self, *google_static_domains

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/font-src
    # Note: we purposely don't include data here because it produces a security risk.
    policy.font_src :self

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/connect-src
    policy.connect_src :self,
                       *govuk_domains,
                       *google_analytics_domains

    # Disallow all <object>, <embed>, and <applet> elements
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/object-src
    policy.object_src :none

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/frame-src
    policy.frame_src :self, *govuk_domains

    policy.report_uri ENV.fetch("SENTRY_CSP_REPORT_URI") if ENV["SENTRY_CSP_REPORT_URI"].present?
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # For now, only report to any reports to Sentry in production
  config.content_security_policy_report_only = true
end
