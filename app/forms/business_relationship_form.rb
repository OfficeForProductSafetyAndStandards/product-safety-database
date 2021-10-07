class BusinessRelationshipForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :relationship
  attribute :relationship_other

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
  validates_presence_of  :relationship_other, if: -> { relationship == "other" }

  def self.from(investigation_business)
    if BUSINESS_TYPES.key?(investigation_business.relationship.downcase)
      new(relationship: investigation_business.relationship, relationship_other: nil)
    else
      new(relationship: "other", relationship_other: investigation_business.relationship)
    end
  end
end
