module BulkProductsHelper
  def new_record_for_product(product)
    new_record = @products_cache.detect { |cached_product| cached_product["barcode"] == product.barcode }
    Product.new(new_record["product_data"].except("image", "existing_image_file_id"))
  end
end
