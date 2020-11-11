module UploadedFile
  extend ActiveSupport::Concern

  def cache_file!(file_attribute)
    file = public_send(file_attribute)
    return if file.blank?

    public_send(
      "#{file_attribute}=",
      ActiveStorage::Blob.create_after_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )
    )

    public_send("existing_#{file_attribute}_file_id=", public_send(file_attribute).signed_id)
  end

  def load_uploaded_file(file_attribute)
    if public_send("existing_#{file_attribute}_file_id").present? && public_send(file_attribute).nil?
      public_send("#{file_attribute}=", ActiveStorage::Blob.find_signed(public_send("existing_#{file_attribute}_file_id")))
    end
  end
end
