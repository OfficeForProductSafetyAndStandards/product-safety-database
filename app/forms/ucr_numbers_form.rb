class UcrNumbersForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :ucr_numbers_attributes

  def self.from(investigation_product)
    new(investigation_product.serializable_hash).tap do |form|
      form.ucr_numbers_attributes = investigation_product.ucr_numbers.map(&:serializable_hash)
    end
  end
end
