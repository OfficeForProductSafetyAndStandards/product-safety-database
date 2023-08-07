module Prism
  class ApplicationController < ActionController::Base
    include Pagy::Backend

    protect_from_forgery with: :exception

    before_action :authenticate_user!
    before_action :authorize_user

    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

    def after_sign_in_path_for(*)
      serious_risk_path
    end

    def after_sign_out_path_for(*)
      root_path
    end

    def root_path_for(*)
      root_path
    end

  private

    def authorize_user
      redirect_to "/403" if current_user && !current_user.is_prism_user?
    end
  end
end
