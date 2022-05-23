class DeleteUnsafeFilesJob < ApplicationJob
  def perform
    unsafe_blobs = ActiveStorage::Blob.where("metadata LIKE ?", '%"safe":false%')

    unsafe_blobs.each do |blob|
      user = User.find(blob.metadata["created_by"]) if blob.metadata["created_by"]
      unsafe_attachments = ActiveStorage::Attachment.where(blob_id: blob.id)
      if unsafe_attachments.empty?
        delete_blob(blob, user)
      else
        delete_attachments(unsafe_attachments, user)
      end
    end
  end

private

  def delete_attachments(attachments, user)
    attachments.each do |attachment|
      NotifyMailer.unsafe_attachment(user:, record_type: attachment.record_type, id: attachment.record_id).deliver_later if user && attachment.record_type != "Activity"
      attachment.purge
      if attachment.record_type == "Activity"
        Activity.find(attachment.record_id).destroy!
      end
    end
  end

  def delete_blob(blob, user)
    blob.purge
    NotifyMailer.unsafe_file(user:).deliver_later if user
  end
end
