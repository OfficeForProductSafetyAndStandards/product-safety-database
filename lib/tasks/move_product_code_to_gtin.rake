require "barkick"

namespace :products do
  desc "Move valid GTIN (barcodes) from the product_code field to the new gtin field"
  task move_valid_product_codes_to_gtin: :environment do
    valid_codes_moved = 0

    Product
      .where.not(product_code: [nil, ""])
      .where(gtin: nil)
      .find_each do |product|
      gtin = Barkick::GTIN.new(product.product_code)

      if gtin.valid?
        product.gtin = gtin.gtin13.to_s
        product.product_code = nil
        product.save!

        valid_codes_moved += 1
      end

    # 8 digit barcodes are are ambiguous and need a 'type' to be interpreted,
    # so skip them.
    rescue ArgumentError
      next
    end

    puts "Barcodes moved for #{valid_codes_moved} products"
  end
end
