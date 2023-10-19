# frozen_string_literal: true
require "companies_house/client"
class CompaniesHouseService

  COMPANIES_HOUSE_API_KEY = ENV.fetch("COMPANIES_HOUSE_API_KEY")

  def initialize
    return if COMPANIES_HOUSE_API_KEY.blank?

    @client = CompaniesHouse::Client.new(api_key: COMPANIES_HOUSE_API_KEY)
  end

  def company_search(query, items_per_page: 25, start_index: 0)
    CompaniesHouseResultSerializer.new(@client.company_search(query, items_per_page:, start_index:))
  end

  def company_profile(company_number)
    @client.company(company_number)
  end
end
