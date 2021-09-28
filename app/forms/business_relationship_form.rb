class BusinessRelationshipForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :relationship
  attribute :relationship_other
  attribute :id

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
  validates_presence_of :relationship_other, if: -> { relationship == "other" }

  def attributes
    byebug
    calculate_relationship.merge(id: id)
  end

  def calculate_relationship
    if relationship != "other"
      {
        relationship: relationship,
        relationship_other: nil
      }
    else
      {
        relationship: "other",
        relationship_other: relationship
      }
    end
  end
end
