module Investigations
  class ImagesController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?
      @investigation = investigation.decorate
    end
  end
end
