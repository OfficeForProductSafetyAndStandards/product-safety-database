module Investigations
  class ActivitiesController < ApplicationController
    include ActionView::Helpers::SanitizeHelper
    include LoadHelper

    def show
      set_investigation_with_associations
      @investigation = @investigation.decorate

      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end

    def new
      set_investigation
      authorize @investigation, :update?

      return unless params[:commit] == "Continue"

      case params[:activity_type]
      when "comment"
        redirect_to new_investigation_activity_comment_path(@investigation)
      when "email"
        redirect_to new_investigation_email_path(@investigation)
      when "phone_call"
        redirect_to new_investigation_phone_call_path(@investigation)
      when "meeting"
        redirect_to new_investigation_meeting_path(@investigation)
      when "product"
        redirect_to new_investigation_product_path(@investigation)
      when "testing_request"
        redirect_to new_request_investigation_tests_path(@investigation)
      when "testing_result"
        redirect_to new_result_investigation_tests_path(@investigation)
      when "corrective_action"
        redirect_to new_investigation_corrective_action_path(@investigation)
      when "business"
        redirect_to new_investigation_business_path(@investigation)
      when "alert"
        redirect_to new_investigation_alert_path(@investigation)
      else
        @activity_type_empty = true
      end
    end

  private

    def set_investigation
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :view_non_protected_details?
      @investigation = investigation.decorate
    end

    def set_investigation_with_associations
      investigation = Investigation
                         .eager_load(:creator_user,
                                     products: { documents_attachments: :blob },
                                     investigation_businesses: { business: :locations },
                                     documents_attachments: :blob)
                         .find_by!(pretty_id: params[:investigation_pretty_id])

      authorize investigation, :view_non_protected_details?
      @investigation = investigation.decorate
      preload_activities
    end

    def preload_activities
      @activities = @investigation.activities.eager_load(:source)
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
        [{ transcript_attachment: :blob }, { related_attachment_attachment: :blob }]
      )
      preload_manually(
        @activities.select { |a| a.respond_to?("correspondence") },
        [:correspondence]
      )
    end
  end
end
