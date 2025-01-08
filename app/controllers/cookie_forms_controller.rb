class CookieFormsController < ApplicationController
  skip_before_action :authenticate_user!,
                     :require_secondary_authentication

  def create
    first_time = analytics_cookies_not_set?
    cookie_form = CookieForm.new(cookie_form_params)

    set_analytics_cookies(cookie_form.accept_analytics_cookies)
    if first_time && !cookie_form.referrer_is_cookie_policy_page
      redirect_back(fallback_location: help_cookies_policy_path, cookies_banner_confirmation: true)
    else
      redirect_back(fallback_location: help_cookies_policy_path, cookies_updated_successfully: true)
    end
  end

private

  def cookie_form_params
    params.fetch(:cookie_form, {}).permit(:accept_analytics_cookies, :referrer_is_cookie_policy_page)
  end
end
