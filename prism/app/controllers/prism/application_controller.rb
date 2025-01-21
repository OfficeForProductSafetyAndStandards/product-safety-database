module Prism
  class ApplicationController < ActionController::Base
    include Pagy::Backend
    include CookiesConcern
    helper ::GoogleTagManagerHelper

    protect_from_forgery with: :exception

    before_action :authenticate_user!

    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

    rescue_from ActiveRecord::RecordNotFound, with: -> { redirect_to "/404" }

    def after_sign_in_path_for(*)
      serious_risk_path
    end

    def after_sign_out_path_for(*)
      root_path
    end

    def root_path_for(*)
      root_path
    end
  end
end
