class SecureBlobsController < ApplicationController
  include ActiveStorage::SetBlob
  include ActiveStorage::SetCurrent

  def show
    redirect_to @blob.service_url(disposition: params[:disposition])
  end

  private

  def authenticate_user!
    if user_signed_in?
      super
    else
      redirect_to unauthenticated_root_path
    end
  end
end
