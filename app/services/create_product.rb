class CreateProduct
  include Interactor

  delegate :authenticity,
           :has_markings,
           :markings,
           :brand,
           :country_of_origin,
           :description,
           :barcode,
           :name,
           :product_code,
           :subcategory,
           :webpage,
           :investigation,
           :category,
           :product,
           :when_placed_on_market,
           to: :context

  def call
    context.product = Product.create!(
      authenticity:,
      has_markings:,
      markings:,
      brand:,
      country_of_origin:,
      description:,
      barcode:,
      name:,
      product_code:,
      subcategory:,
      category:,
      webpage:,
      when_placed_on_market:
    )
  end
end
