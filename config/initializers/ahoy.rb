class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # disables automatic linking of visits and users
  end
end

# GDPR compliance - no cookies & use anonymity sets instead of IPs
Ahoy.mask_ips = true
Ahoy.cookies = :none

Ahoy.visit_duration = 4.hours

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
