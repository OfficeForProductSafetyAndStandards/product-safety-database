module Investigations
  class SupportingInformationController < ApplicationController
    def index
      authorize investigation, :view_non_protected_details?

      @supporting_information       = Investigation::SupportingInformationDecorator.new(investigation.supporting_information.map(&:decorate), params[:sort_by])
      @other_supporting_information = investigation.generic_supporting_information_attachments.decorate

      @breadcrumbs = {
        items: [
          { text: "Cases", href: investigations_path(previous_search_params) },
          { text: @investigation.pretty_description }
        ]
      }
    end

    def new
      authorize investigation, :update?
      supporting_information_type_form
    end

    def create
      authorize investigation, :update?
      return render(:new) if supporting_information_type_form.invalid?

      case supporting_information_type_form.type
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
      end
    end

  private

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end

    def supporting_information_type_form
      @supporting_information_type_form ||= SupportingInformationTypeForm.new(type: params[:type])
    end
  end
end
