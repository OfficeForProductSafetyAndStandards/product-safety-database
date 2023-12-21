class BulkProductsResolveDuplicateProductsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :random_uuid
  attribute :duplicate_barcodes, default: []
  attribute :resolution, default: {}

  validate :all_duplicate_barcodes_have_resolution

private

  def all_duplicate_barcodes_have_resolution
    duplicate_barcodes.each do |barcode|
      errors.add(barcode, "Select whether to use the existing PSD record or the imported Excel record") unless %w[new_record existing_record].include?(resolution[barcode]&.split(";")&.first)
    end
  end
end
