class CookieForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :accept_analytics_cookies, :boolean
  attribute :referrer_is_cookie_policy_page, :boolean
end
