class UpdateBusiness
  include Interactor

  delegate :business, :business_params, to: :context

  def call
    context.fail!(error: "No business supplied") unless product.is_a?(Business)
    context.fail!(error: "No business params supplied") unless product_params.is_a?(Hash)

    Business.transaction do
      business.update!(business_params)

      business.investigations.import
    end
  end
end
