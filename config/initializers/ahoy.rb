if defined?(Ahoy)
  class Ahoy::Store < Ahoy::DatabaseStore
  end

  Ahoy.mask_ips = true
  Ahoy.api = false
  Ahoy.geocode = false
end