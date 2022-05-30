module SetSentryBlobContext
  extend ActiveSupport::Concern

  included do
    before_action :set_sentry_blob_context
  end

private

  def set_sentry_blob_context
    return unless @blob

    Sentry.configure_scope do |scope|
      scope.set_context(
        "blob",
        @blob.serializable_hash(
          only: %i[id byte_size key content_type],
          include: {
            attachments: {
              only: %i[id record_type record_id name]
            }
          }
        )
      )
    end
  end
end
