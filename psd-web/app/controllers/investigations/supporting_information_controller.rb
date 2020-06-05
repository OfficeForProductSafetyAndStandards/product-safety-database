module Investigations
  class SupportingInformationController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      @investigation                = investigation.decorate
      @supporting_information       = investigation.supporting_information_attachments.includes(:blob).decorate
      supporting_information_creator_ids = investigation.supporting_information_attachments.map(&:blob).map { |blob| blob.metadata["created_by"] }
      users = User.where(id: supporting_information_creator_ids).decorate
      @creators_by_blob_id = investigation.supporting_information_attachments.each_with_object({}) do |supporting_information, acc|
        acc[supporting_information.blob_id] = users.detect { |user| user.id == supporting_information.blob.metadata["created_by"] }
        acc
      end
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
