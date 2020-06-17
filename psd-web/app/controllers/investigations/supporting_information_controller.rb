module Investigations
  class SupportingInformationController < ApplicationController
    def index
      authorize investigation, :view_non_protected_details?
      set_breadcrumbs

      @supporting_information       = @investigation.supporting_information.map(&:decorate)
      @other_supporting_information = @investigation.generic_supporting_information_attachments.decorate
    end

    def new
      authorize investigation, :update?
      set_breadcrumbs
    end

    def create
      authorize investigation, :update?

      case params[:supporting_information_type]
      when "comment"
        redirect_to new_investigation_activity_comment_path(@investigation)
      when "corrective_action"
        redirect_to new_investigation_corrective_action_path(@investigation)
      when "correspondence"
        redirect_to new_investigation_correspondence_path(@investigation)
      when "image", "generic_information"
        redirect_to new_investigation_new_path(@investigation)
      when "testing_result"
        redirect_to new_result_investigation_tests_path(@investigation)
      else
        @supporting_information_type_empty = true
        set_breadcrumbs
        render :new
      end
    end

  private

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end

    def set_breadcrumbs
      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end
  end
end
