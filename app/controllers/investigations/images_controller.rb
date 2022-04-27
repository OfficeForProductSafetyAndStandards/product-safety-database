module Investigations
  class ImagesController < ApplicationController
    def index
      investigation = Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?
      @investigation = investigation.decorate

      @images_with_viruses_present = images_with_viruses_created_by_current_user.any?
      destroy_images_with_viruses
      # @images_with_viruses.each { |image| image.update(metadata: image.metadata.merge({ user_notified: true })) }

      @breadcrumbs = {
        items: [
          { text: "Cases", href: all_cases_investigations_path },
          { text: @investigation.pretty_description }
        ]
      }
    end

    private

    def images_with_viruses_created_by_current_user
      @investigation.images.map(&:blob).select { |b| b.metadata["safe"] == false && b.metadata["created_by"] == current_user.id }
    end

    def destroy_documents_with_viruses
      images_with_viruses_created_by_current_user.each do |image|
        DeleteDocument.call!(user: current_user, parent: image.parent, document: image)
      end
    end
  end
end
