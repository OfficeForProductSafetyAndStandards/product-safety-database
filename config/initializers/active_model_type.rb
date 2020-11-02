require "active_model/types/govuk_date"
require "active_model/types/business_list"
ActiveModel::Type.register(:govuk_date, ActiveModel::Types::GovUKDate)
ActiveRecord::Type.register(:govuk_date, ActiveModel::Types::GovUKDate)
ActiveModel::Type.register(:business_list, ActiveModel::Types::BusinessList)
