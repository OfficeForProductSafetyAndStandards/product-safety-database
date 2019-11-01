module Investigations
  class AttachmentsController < ApplicationController
    def index
      @investigation = Investigation
                         .includes(:products, :businesses, :documents_attachments, :documents_blobs)
                         .find_by!(pretty_id: params[:investigation_pretty_id])
      authorize @investigation, :show?

      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end
  end
end
