# frozen_string_literal: true

#
# Overrides original Rails implementation to disable route:
# /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)
# We use "rails storage proxy" through ActiveStorage::Blobs::ProxyController

class ActiveStorage::Representations::ProxyController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob
  include HttpAuthConcern
  include SentryConfigurationConcern

  before_action :authorize_blob

  def show
    set_content_headers_from representation.image
    stream representation
  end

private

  def authorize_blob
    redirect_to "/sign-in" unless user_signed_in?
  end

  def representation
    @blob.representation(params[:variation_key]).processed
  end
end
