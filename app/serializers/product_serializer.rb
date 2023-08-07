class ProductSerializer < ActiveModel::Serializer
  attributes :product_code, :subcategory, :description, :barcode
end
