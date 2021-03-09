class Country
  PATH_TO_COUNTRIES_LIST =
    "node_modules/govuk-country-and-territory-autocomplete/dist/location-autocomplete-canonical-list.json".freeze

  ADDITIONAL_COUNTRIES = [
    ["England", "countries:GB-ENG"],
    ["Scotland", "countries:GB-SCT"],
    ["Wales", "countries:GB-WLS"],
    ["Northern Ireland", "countries:GB-NIR"]
  ]


  class << self
    def all
      @all ||= JSON.parse(File.read(PATH_TO_COUNTRIES_LIST))
    end

    def notifying_countries
      all + ADDITIONAL_COUNTRIES
    end
  end
end
