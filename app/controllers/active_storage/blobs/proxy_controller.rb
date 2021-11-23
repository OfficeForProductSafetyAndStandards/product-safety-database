# frozen_string_literal: true

#
# Proxy files through application. This avoids having a redirect and makes files easier to cache.
# Overrides Rails Controller to enforce access protection beyond the security-through-obscurity
# factor of the signed blob and variation reference.
# Only owners and search users have access to files.

class ActiveStorage::Blobs::ProxyController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob
  include ActiveStorage::SetHeaders
  include ActiveStorage::SetCurrent
  include HttpAuthConcern
  include SentryConfigurationConcern
  include Pundit

  self.etag_with_template_digest = false

  before_action :authorize_blob

  def show
    set_content_headers_from @blob
    stream @blob
  end

private

  def authorize_blob
    return redirect_to "/sign-in" unless user_signed_in?

    if investigation
      if attachment_is_correspondence_or_non_image_investigation_attachment? && !InvestigationPolicy.new(current_user, investigation).view_protected_details?
        return redirect_to "/", flash: { warning: "Not authorized to view this attachment" }
      end

      return redirect_to "/", flash: { warning: "Not authorized to view this attachment" } unless InvestigationPolicy.new(current_user, investigation).view_non_protected_details?
    end
  end

  def attachment_categorizer
    AttachmentCategorizer.new(@blob)
  end

  def investigation
    attachment_categorizer.related_investigation
  end

  def non_activity_attachment
    attachment_categorizer.non_activity_attachment
  end

  def is_an_image?
    attachment_categorizer.is_an_image?
  end

  def is_an_investigation_image?
    non_activity_attachment.record_type == "Investigation" && is_an_image?
  end

  def attachment_is_correspondence_or_non_image_investigation_attachment?
    non_activity_attachment.record_type == "Correspondence" || investigation && !is_an_image?
  end
end
