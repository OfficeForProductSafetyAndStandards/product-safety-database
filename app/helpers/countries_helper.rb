module CountriesHelper
  # JSON is of the form [["Abu Dhabi", "territory:AE-AZ"], ["Afghanistan", "country:AF"]]
  def country_from_code(code, countries = all_countries)
    country = countries.find { |c| c[1] == code }
    (country && country[0]) || code
  end

  def set_countries
    @countries = all_countries
  end

  def all_countries
    Country.all
  end

  def all_countries_with_uk_first
    Country::UNITED_KINGDOM + (all_countries - Country::UNITED_KINGDOM)
  end
end
