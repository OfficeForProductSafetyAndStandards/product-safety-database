module CompaniesHouseApi
  module Company
    class ProfileSerializer < ActiveModel::Serializer
      attributes :company_number, :company_name, :company_status, :date_of_confirmation
      has_one :registered_office_address, serializer: AddressSerializer
    end
  end
end
