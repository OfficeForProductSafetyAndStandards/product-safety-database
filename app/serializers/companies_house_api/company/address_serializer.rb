module CompaniesHouseApi
  module Company
    class AddressSerializer < ActiveModel::Serializer
      attributes :address_line_1, :address_line_2, :locality, :postal_code, :country
    end
  end
end
