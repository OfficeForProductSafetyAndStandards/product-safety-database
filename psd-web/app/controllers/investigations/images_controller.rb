module Investigations
  class ImagesController < ApplicationController
    def index
      investigation = Investigation
                        .with_attached_documents
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?
      @investigation = investigation.decorate
      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end
  end
end
