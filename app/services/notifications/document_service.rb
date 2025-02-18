module Notifications
  class DocumentService
    def initialize(notification, current_user)
      @notification = notification
      @current_user = current_user
    end

    def save_document(document_form)
      return false unless document_form.valid?

      document_form.cache_file!(@current_user)
      @notification.documents.attach(document_form.document)
      true
    end

    def remove_document(upload)
      upload.destroy!
      true
    rescue StandardError => e
      Rails.logger.error("Failed to remove document: #{e.message}")
      false
    end
  end
end
