# frozen_string_literal: true

# Overrides original Rails implementation to disable route:
# /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)
# We use "rails storage proxy" through ActiveStorage::Blobs::ProxyController

class ActiveStorage::Representations::ProxyController < ActiveStorage::Representations::BaseController
  include ActiveStorage::Streaming
  include HttpAuthConcern
  include SentryConfigurationConcern
  include SetSentryBlobContext

  before_action :authorize_blob

  def show
    http_cache_forever public: true do
      send_blob_stream @representation.image, disposition: params[:disposition]
    end
  rescue ActiveStorage::FileNotFoundError
    redirect_to "/404"
  end

private

  def authorize_blob
    redirect_to "/sign-in" unless user_signed_in?
  end
end
