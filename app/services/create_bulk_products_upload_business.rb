class CreateBulkProductsUploadBusiness
  include Interactor

  delegate :bulk_products_upload, :type, :online_marketplace_id, :other_marketplace_name, :authorised_representative_choice, :user, to: :context

  def call
    context.fail!(error: "No bulk products upload supplied") unless bulk_products_upload.is_a?(BulkProductsUpload)
    context.fail!(error: "No type supplied") unless type.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      # Use a fake name for now
      business = Business.create!(
        trading_name: "Auto-generated business for notification #{bulk_products_upload.investigation.pretty_id}",
        added_by_user: user
      )

      # Location will not be valid until a country is added at the next step
      business.locations.build(name: "Registered office address", added_by_user: user).save!(validate: false)

      business.contacts.create!

      AddBusinessToNotification.call!(
        business:,
        relationship: type,
        online_marketplace: online_marketplace_id.present? ? OnlineMarketplace.find(online_marketplace_id) : nil,
        other_marketplace_name:,
        authorised_representative_choice:,
        investigation: bulk_products_upload.investigation,
        user:,
        skip_email: true
      )

      # Keep track of the investigation business so we can refer to it unambiguously later
      # Keep track of the new business so we can destroy it later if required
      bulk_products_upload.update!(investigation_business_id: business.reload.investigation_businesses.first.id, business_id: business.reload.id)
    end
  end
end
