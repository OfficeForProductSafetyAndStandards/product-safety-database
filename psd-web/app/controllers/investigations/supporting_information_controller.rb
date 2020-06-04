module Investigations
  class SupportingInformationController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      @investigation                = investigation.decorate
      @supporting_information       = investigation.supporting_information_attachment.decorate
      @other_supporting_information = investigation.generic_supporting_information_attachments.decorate

      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end
  end
end
