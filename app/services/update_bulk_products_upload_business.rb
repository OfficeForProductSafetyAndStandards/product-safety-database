class UpdateBulkProductsUploadBusiness
  include Interactor

  delegate :bulk_products_upload, :type, :online_marketplace_id, :other_marketplace_name, :authorised_representative_choice, :user, to: :context

  def call
    context.fail!(error: "No bulk products upload supplied") unless bulk_products_upload.is_a?(BulkProductsUpload)
    context.fail!(error: "No type supplied") unless type.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    online_marketplace = if other_marketplace_name.present?
                           OnlineMarketplace.find_or_create_by!(name: other_marketplace_name, approved_by_opss: false)
                         else
                           OnlineMarketplace.find(online_marketplace_id)
                         end

    bulk_products_upload.investigation_business.update!(
      relationship: type,
      online_marketplace:,
      authorised_representative_choice:
    )
  end
end
