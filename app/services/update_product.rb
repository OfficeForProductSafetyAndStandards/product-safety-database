class UpdateProduct
  include Interactor

  delegate :product, :product_params, to: :context

  def call
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "No product supplied") unless product_params.is_a?(Hash)

    Product.transaction do
      product.update!(product_params)

    end
  end
end
