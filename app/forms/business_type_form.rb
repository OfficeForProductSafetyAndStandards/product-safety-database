class BusinessTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :relationship, default: ""
  attribute :other_relationship

  BUSINESS_TYPES = {
    "retailer" => "Retailer",
    "manufacturer" => "Manufacturer",
    "exporter" => "Exporter",
    "importer" => "Importer",
    "fulfillment_house" => "Fulfillment house",
    "distributor" => "Distributor",
    "other" => "Other"

  }.freeze

  validates_inclusion_of :relationship, in: BUSINESS_TYPES.keys
  validates_presence_of :other_relationship, if: -> { relationship.inquiry.other? }
end
