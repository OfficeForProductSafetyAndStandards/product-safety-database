class SetBusinessTypeOnCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :type
  attribute :online_marketplace_id

  BUSINESS_TYPES = %w[
    retailer online_marketplace manufacturer exporter importer fulfillment_house distributor
  ].freeze

  validates_inclusion_of :type, in: BUSINESS_TYPES
end
