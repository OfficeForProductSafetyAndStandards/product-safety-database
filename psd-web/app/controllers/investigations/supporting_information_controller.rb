module Investigations
  class SupportingInformationController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      @investigation                = investigation.decorate
      @supporting_information       = Investigation::SupportingInformationDecorator.new(investigation.supporting_information, params[:sort_by])
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
