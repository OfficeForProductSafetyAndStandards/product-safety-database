module Investigations
  class ActivitiesController < Investigations::BaseController
    include ActionView::Helpers::SanitizeHelper
    before_action :set_investigation_with_associations
    before_action :set_investigation_breadcrumbs

    def show
      @investigation = @investigation.decorate
    end

  private

    def set_investigation_with_associations
      investigation = Investigation
                         .eager_load(:creator_user,
                                     products: { documents_attachments: :blob },
                                     investigation_businesses: { business: :locations },
                                     documents_attachments: :blob)
                         .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?

      preload_activities(investigation)

      @investigation = investigation.decorate
    end

    def preload_activities(investigation)
      @activities = investigation.activities.eager_load(:added_by_user)
      preload_manually(
        @activities.select { |a| a.respond_to?("attachment") },
        [{ attachment_attachment: :blob }]
      )
      preload_manually(
        @activities.select { |a| a.respond_to?("email_file") },
        [{ email_file_attachment: :blob }, { email_attachment_attachment: :blob }]
      )
      preload_manually(
        @activities.select { |a| a.respond_to?("transcript") },
        [{ transcript_attachment: :blob }]
      )
      preload_manually(
        @activities.select { |a| a.respond_to?("correspondence") },
        [:correspondence]
      )
    end

    def preload_manually(records, associations)
      ActiveRecord::Associations::Preloader.new(records:, associations:).call
    end
  end
end
