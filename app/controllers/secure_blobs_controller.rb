class SecureBlobsController < ApplicationController
  include ActiveStorage::SetBlob

  def show
    redirect_to @blob.service_url(disposition: params[:disposition])
  end
end
