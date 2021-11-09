class SecureBlobsController < ApplicationController
  include ActiveStorage::SetBlob
  include ActiveStorage::SetCurrent

  def show
    redirect_to @blob.service_url(disposition: params[:disposition])
  end
end
