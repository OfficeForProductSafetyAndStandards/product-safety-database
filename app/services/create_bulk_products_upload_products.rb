class CreateBulkProductsUploadProducts
  include Interactor

  delegate :bulk_products_upload, :new_products, :existing_products, :images, :user, to: :context

  def call
    context.fail!(error: "No bulk products upload supplied") unless bulk_products_upload.is_a?(BulkProductsUpload)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      # Products added via file upload
      products = new_products.map do |new_product|
        context = CreateProduct.call!(new_product[:product].serializable_hash.merge(user:))
        product = context.product

        # If an image has been added at the review stage, upload it and associate it with the product
        if images[product.barcode].present?
          uploaded_image = images[product.barcode]

          image = ActiveStorage::Blob.create_and_upload!(
            io: uploaded_image,
            filename: uploaded_image.original_filename,
            content_type: uploaded_image.content_type
          )

          image.analyze_later

          image_upload = ImageUpload.create!(upload_model: product, created_by: user.id, file_upload: image.signed_id)

          product.image_upload_ids.push(image_upload.id)
          product.save!
        end

        AddProductToCase.call!(investigation: bulk_products_upload.investigation, product:, user:, skip_email: true)

        product.investigation_products.first.update!(new_product[:investigation_product].serializable_hash.slice("batch_number", "customs_code", "number_of_affected_units").merge(affected_units_status: "exact"))

        product
      end

      # Keep track of new products so we can destroy them later if required
      bulk_products_upload.products << products
      bulk_products_upload.save!

      # Products that already exist
      existing_products.each do |existing_product|
        context = AddProductToCase.call!(investigation: bulk_products_upload.investigation, product: existing_product[:product], user:, skip_email: true)
        context.investigation_product.update!(existing_product[:investigation_product].serializable_hash.slice("batch_number", "customs_code", "number_of_affected_units").merge(affected_units_status: "exact"))
      end
    end
  end
end
