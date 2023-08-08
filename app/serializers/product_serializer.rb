class ProductSerializer < ActiveModel::Serializer
  attributes :name, :product_code, :subcategory, :description, :barcode
end
