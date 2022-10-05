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
           :user,
           :product,
           :when_placed_on_market,
           to: :context

  def call
    context.fail!(error: "No user supplied") unless user.is_a?(User)
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
      when_placed_on_market:,
      owning_team: user.team
    )
  end
end
