require "active_model/types/govuk_date"
require "active_model/types/business_list"
require "active_model/types/comma_separated_list"

ActiveModel::Type.register(:govuk_date, ActiveModel::Types::GovukDate)
ActiveRecord::Type.register(:govuk_date, ActiveModel::Types::GovukDate)
ActiveModel::Type.register(:business_list, ActiveModel::Types::BusinessList)
ActiveModel::Type.register(:comma_separated_list, ActiveModel::Types::CommaSeparatedList)
