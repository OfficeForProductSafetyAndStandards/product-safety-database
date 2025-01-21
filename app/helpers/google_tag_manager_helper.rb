module GoogleTagManagerHelper
  def gtm_containers
    return [] unless Rails.env.production? && analytics_cookies_accepted?

    %w[GTM-K2S954RK]
  end
end
