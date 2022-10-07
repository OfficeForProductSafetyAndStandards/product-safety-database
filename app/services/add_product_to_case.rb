class AddProductToCase
  include Interactor

  delegate :investigation,
           :user,
           :product,
           to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "No product supplied") unless product.is_a?(Product)

    investigation.products << product
  end
end
