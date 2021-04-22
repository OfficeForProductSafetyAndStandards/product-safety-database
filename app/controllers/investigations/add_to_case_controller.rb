module Investigations
  class AddToCaseController < ApplicationController
    before_action :set_options_to_add
    
    def new
      authorize investigation, :update?
      @supporting_information_type_form = SupportingInformationTypeForm.new
    end

    def create
      authorize investigation, :update?
      @supporting_information_type_form = SupportingInformationTypeForm.new(type: params[:type])
      return render(:new) if @supporting_information_type_form.invalid?

      case @supporting_information_type_form.type
      when "accident_or_incident"
        redirect_to new_investigation_accident_or_incidents_type_path(investigation)
      when "comment"
        redirect_to new_investigation_activity_comment_path(investigation)
      when "corrective_action"
        redirect_to new_investigation_corrective_action_path(investigation)
      when "correspondence"
        redirect_to new_investigation_correspondence_path(investigation)
      when "image", "generic_information"
        redirect_to new_investigation_new_path(investigation)
      when "testing_result"
        redirect_to new_investigation_test_result_path(investigation)
      when "risk_assessment"
        redirect_to new_investigation_risk_assessment_path(investigation)
      when "product"
        redirect_to new_investigation_product_path(investigation)
      when "business"
        redirect_to new_investigation_business_path(investigation)
      end
    end

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end

    def set_options_to_add
      @options_to_add = SupportingInformationTypeForm::MAIN_TYPES.merge({ product: "Product", business: "Business" })
    end
  end
end
