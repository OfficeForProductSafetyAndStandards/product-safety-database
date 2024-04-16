# frozen_string_literal: true

# Proxy files through application. This avoids having a redirect and makes files easier to cache.
# Overrides Rails Controller to enforce access protection beyond the security-through-obscurity
# factor of the signed blob and variation reference.
# Only owners and search users have access to files.

class ActiveStorage::Blobs::ProxyController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob
  include ActiveStorage::Streaming
  include HttpAuthConcern
  include SentryConfigurationConcern
  include SetSentryBlobContext
  include Pundit::Authorization

  self.etag_with_template_digest = false

  before_action :authorize_blob

  def show
    if request.headers["Range"].present?
      send_blob_byte_range_data @blob, request.headers["Range"]
    else
      http_cache_forever public: true do
        response.headers["Accept-Ranges"] = "bytes"
        response.headers["Content-Length"] = @blob.byte_size.to_s

        send_blob_stream @blob, disposition: params[:disposition]
      end
    end
  end

private

  def authorize_blob
    return redirect_to "/sign-in" unless user_signed_in?

    if related_investigation
      if attachment_is_protected_type? && !InvestigationPolicy.new(current_user, related_investigation).view_protected_details?
        return redirect_to "/", flash: { warning: I18n.t("attachments.unauthorised") }
      end

      redirect_to "/", flash: { warning: I18n.t("attachments.unauthorised") } unless InvestigationPolicy.new(current_user, related_investigation).view_non_protected_details?
    end
  end

  def attachment_categorizer
    AttachmentCategorizer.new(@blob)
  end

  def related_investigation
    attachment_categorizer.related_investigation
  end

  def attachment
    attachment_categorizer.attachment
  end

  def is_an_image?
    attachment_categorizer.is_an_image?
  end

  def is_a_correspondence_or_correspondence_activity_document?
    attachment.record_type == "Correspondence" || attachment_categorizer.is_a_correspondence_activity?
  end

  def is_a_non_image_investigation_document?
    attachment.record_type == "Investigation" && !is_an_image? || attachment_categorizer.is_an_investigation_document? && !is_an_image?
  end

  def attachment_is_protected_type?
    is_a_correspondence_or_correspondence_activity_document? || is_a_non_image_investigation_document?
  end
end
