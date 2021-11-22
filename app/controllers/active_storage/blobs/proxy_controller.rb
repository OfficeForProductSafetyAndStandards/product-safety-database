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
      if attachment_is_correspondence_or_generic_investigation_attachment?
        return redirect_to "/", flash: { warning: "Not authorized to view this attachment" } unless InvestigationPolicy.new(current_user, investigation).view_protected_details?
      end

      return redirect_to "/", flash: { warning: "Not authorized to view this attachment" } unless InvestigationPolicy.new(current_user, investigation).view_non_protected_details?
    end
  end

  def related_correspondence
    correspondence_id = @blob.attachments.find_by(record_type: "Correspondence").try(:record_id)
    Correspondence.find(correspondence_id) if correspondence_id
  end

  def related_corrective_action
    corrective_action_id = @blob.attachments.find_by(record_type: "CorrectiveAction").try(:record_id)
    CorrectiveAction.find(corrective_action_id) if corrective_action_id
  end

  def related_test
    test_id = @blob.attachments.find_by(record_type: "Test").try(:record_id)
    Test.find(test_id) if test_id
  end

  def related_investigation
    investigation_id = @blob.attachments.find_by(record_type: "Investigation").try(:record_id)
    Investigation.find(investigation_id) if investigation_id
  end

  def is_an_investigation_image?
    investigation_attachment = @blob.attachments.find_by(record_type: "Investigation")
    return false unless investigation_attachment
    return true if investigation_attachment.content_type.include?("image")
  end

  def investigation
    if related_correspondence
      related_correspondence.investigation
    elsif related_corrective_action
      related_corrective_action.investigation
    elsif related_test
      related_test.investigation
    elsif related_investigation
      related_investigation
    end
  end

  def attachment_is_correspondence_or_generic_investigation_attachment?
    related_correspondence || investigation && !is_an_investigation_image?
  end
end
