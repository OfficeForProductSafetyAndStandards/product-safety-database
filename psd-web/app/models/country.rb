class Country
  PATH_TO_COUNTRIES_LIST =
    "node_modules/govuk-country-and-territory-autocomplete/dist/location-autocomplete-canonical-list.json".freeze

  class << self
    def all
      @all ||= JSON.parse(File.read(PATH_TO_COUNTRIES_LIST))
    end
  end
end
