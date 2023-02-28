class Country
  PATH_TO_COUNTRIES_LIST = "app/assets/location-autocomplete-canonical-list.json".freeze

  ADDITIONAL_COUNTRIES = [
    ["England", "country:GB-ENG"],
    ["Scotland", "country:GB-SCT"],
    ["Wales", "country:GB-WLS"],
    ["Northern Ireland", "country:GB-NIR"]
  ].freeze

  class << self
    def all
      @all ||= JSON.parse(File.read(PATH_TO_COUNTRIES_LIST))
    end

    def notifying_countries
      all + ADDITIONAL_COUNTRIES
    end
  end
end
