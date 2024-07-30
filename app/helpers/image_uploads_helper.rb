module ImageUploadsHelper
  def image_upload_placeholder(image)
    render "image_uploads/placeholder", image:
  end

  def product_image_preview(image, dimensions)
    render "products/image_preview", image:, dimensions:
  end

  def image_upload_file_extension(image)
    File.extname(image.file_upload.filename.to_s)&.remove(".")&.upcase
  end

  def image_upload_path(image)
    return investigation_image_upload_path(image.upload_model, image) if image.upload_model.is_a?(Investigation)

    return product_image_upload_path(image.upload_model, image) if image.upload_model.is_a?(Product)

    ""
  end

  def image_upload_filename_with_size(image)
    "#{image.file_upload.filename} (#{number_to_human_size(image.file_upload.blob.byte_size)})"
  end

  def image_upload_pretty_type_description(*)
    "image"
  end

  def formatted_image_upload_updated_date(image)
    "Updated #{image_upload_updated_date_in_govuk_format image}"
  end

  def image_upload_updated_date_in_govuk_format(image)
    image.updated_at.to_formatted_s(:govuk)
  end

  def imageable_policy(record)
    # NOTE: record will be the parent record, not the document!
    # NOTE: Pundit doesn't have a policy helper that allows the overriding
    #   of policy_class, so this helper manually instantiates an instance
    ImageablePolicy.new current_user, record
  end
end
