module Investigations
  class SupportingInformationsController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      @investigation                 = investigation.decorate
      @supporting_informations       = investigation.supporting_informations.decorate
      @other_supporting_informations = investigation.other_supporting_informations.decorate

      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end
  end
end
