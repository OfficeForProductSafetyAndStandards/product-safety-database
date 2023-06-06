class UcrNumbersForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :ucr_numbers

  def self.from(investigation_product)
    new(investigation_product.serializable_hash.slice("ucr_numbers"))
  end
end
