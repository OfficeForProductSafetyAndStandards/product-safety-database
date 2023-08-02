class UpdateProduct
  include Interactor

  delegate :product, :product_params, :updating_team, to: :context

  def call
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "No product params supplied") unless product_params.is_a?(Hash)
    context.fail!(error: "No updating team supplied") unless updating_team.is_a?(Team)
    context.fail!(error: "You can not explicitly set a Product's owning team during update") if product_params.key?("owning_team") || product_params.key?("owning_team_id")

    Product.transaction do
      product_params[:owning_team] = updating_team if product.owning_team.nil?

      product.update!(product_params)

      product.investigations.not_deleted.reindex
    end
  end
end
