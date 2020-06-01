module Investigations
  class SupportingInformationsController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      @attachements = ActiveStorage::Attachment.where(
        record: [
          investigation.corrective_actions,
          investigation.correspondences,
          investigation.tests
        ]
      ).decorate

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
