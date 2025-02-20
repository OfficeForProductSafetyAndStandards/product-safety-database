module CookiesConcern
  extend ActiveSupport::Concern

  NON_ESSENTIAL_COOKIES = [/_ga.*/, /_gid/, /_ga_.*/].freeze

  included do
    before_action :set_cookie_form

    add_flash_types :cookies_banner_confirmation, :cookies_updated_successfully

    after_action :try_to_clear_non_essential_cookies

    helper_method :analytics_cookies_accepted?
    helper_method :analytics_cookies_not_set?
  end

  def set_cookie_form
    @cookie_form = CookieForm.new(accept_analytics_cookies: analytics_cookies)
  end

  def try_to_clear_non_essential_cookies
    return if analytics_cookies_accepted?

    cookies_to_delete = request.cookie_jar.select { |name, _|
      NON_ESSENTIAL_COOKIES.any? { |regexp| name =~ regexp }
    }.map(&:first)
    cookies_to_delete.each do |cookie_name|
      request.cookie_jar.delete(cookie_name, domain: request.host)
    end
  end

  def analytics_cookies_accepted?
    analytics_cookies == "true"
  end

  def analytics_cookies_not_set?
    analytics_cookies.nil?
  end

  def analytics_cookies
    cookies[:accept_analytics_cookies]
  end

  def set_analytics_cookies(accept_analytics_cookies)
    cookies[:accept_analytics_cookies] = { value: accept_analytics_cookies, expires: 1.year.from_now }
    cookies[:cookie_preferences_set] = { value: accept_analytics_cookies, expires: 1.year.from_now }

    if accept_analytics_cookies == true
      cookies[:cookies_policy] = {
        value: get_policy.to_json,
        expires: 1.year.from_now,
        httponly: true
      }
    end
  end

private

  def get_policy
    # these would get assigned from the cookie policy form
    {
      essential: true,
      settings: true,
      usage: true,
      campaigns: true
    }
  end
end
