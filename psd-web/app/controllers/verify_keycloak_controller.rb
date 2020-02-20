class VerifyKeycloakController < ApplicationController
  layout "application"

  class CredentialVerification
    include ActiveModel::Model

    attr_accessor :email, :password

    def verify!
      KeycloakCredential.authenticate(email, password)
    rescue ActiveRecord::RecordNotFound
      false
    end
  end

  def index
    if request.get?
      @resource = CredentialVerification.new
    elsif request.post?
      params.permit!
      @resource = CredentialVerification.new(params[:user])
    end
  end

private

  def nav_items
    []
  end
  helper_method :nav_items

  def secondary_nav_items
    []
  end
  helper_method :secondary_nav_items
end
