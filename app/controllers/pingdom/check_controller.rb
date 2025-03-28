module Pingdom
  class CheckController < ApplicationController
    skip_before_action :authenticate_user!,
                       :has_accepted_declaration,
                       :has_viewed_introduction,
                       :require_secondary_authentication

    def pingdom
      respond_to do |format|
        format.xml { render xml: "<pingdom_http_custom_check><status>OK</status><response_time>500</response_time></pingdom_http_custom_check>", status: :ok }
        format.any { return redirect_to "/404" }
      end
    end
  end
end
