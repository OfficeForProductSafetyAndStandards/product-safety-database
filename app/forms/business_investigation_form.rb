class AddBusinessToCaseForm
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
  validates_presence_of :other_relationship, if: :other?

  def attributes
    { relationship: compute_relationship }
  end

  def compute_relationship
    return relationship unless other?

    other_relationship
  end

  def other?
    relationship.inquiry.other?
  end
end
