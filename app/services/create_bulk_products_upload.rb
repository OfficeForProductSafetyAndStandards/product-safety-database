class CreateBulkProductsUpload
  include Interactor

  delegate :hazard_description, :user, :bulk_products_upload, to: :context

  def call
    context.fail!(error: "No hazard description supplied") unless hazard_description.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      investigation = Investigation::Notification.new(reported_reason: "non_compliant", hazard_description:)
      CreateCase.call!(investigation:, user:, bulk: true, silent: true)
      context.bulk_products_upload = BulkProductsUpload.create!(investigation:, user:)
    end
  end
end
