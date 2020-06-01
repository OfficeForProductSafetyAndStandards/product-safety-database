module Investigations
  class SupportingInformationsController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      @supporting_informations = ActiveStorage::Attachment.where(
        record: [
          investigation.corrective_actions,
          investigation.correspondences,
          investigation.tests
        ]
      ).decorate

      @attachements = investigation.non_images_documents.decorate

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
