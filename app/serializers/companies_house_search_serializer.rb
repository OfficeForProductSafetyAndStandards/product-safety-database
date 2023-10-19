
class CompaniesHouseSearchSerializer < ActiveModel::Serializer
  attributes :total_results
  has_many :results, serializer: CompaniesHouseResultSerializer
end

