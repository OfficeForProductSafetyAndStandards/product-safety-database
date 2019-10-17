module CountriesHelper
  # JSON is of the form [["Abu Dhabi", "territory:AE-AZ"], ["Afghanistan", "country:AF"]]
  def country_from_code(code)
    country = all_countries.find { |c| c[1] == code }
    (country && country[0]) || code
  end

  def all_countries
    Country.all
  end
end
