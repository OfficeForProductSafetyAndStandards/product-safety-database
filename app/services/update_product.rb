class UpdateProduct
  include Interactor

  delegate :product, :product_params, to: :context

  def call
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "No product params supplied") unless product_params.is_a?(Hash)
    context.fail!(error: "You can not explicitly set a Product's owning team during update") if product_params.key?("owning_team") || product_params.key?("owning_team_id")

    Product.transaction do
      product.update! product_params
      product.investigations.not_deleted.import
    end
  end
end
