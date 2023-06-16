module Investigations
  class SafetyAndComplianceController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_case_breadcrumbs

    def edit
      @reported_reason = params[:reported_reason]
      @edit_why_reporting_form = EditWhyReportingForm.from(@investigation, @reported_reason)
    end

    def update
      @edit_why_reporting_form = EditWhyReportingForm.new(why_reporting_form_params)
      if @edit_why_reporting_form.valid?
        result = ChangeSafetyAndComplianceData.call!(
          @edit_why_reporting_form.serializable_hash.merge({
            investigation: @investigation,
            user: current_user
          })
        )

        flash[:success] = "The case information was updated" if result.changes_made
        redirect_to investigation_path(@investigation)
      else
        @reported_reason = @edit_why_reporting_form.reported_reason
        render :edit
      end
    end

  private

    def why_reporting_form_params
      params.require(:investigation)
        .permit(
          :hazard_type,
          :hazard_description,
          :non_compliant_reason,
          :reported_reason_unsafe,
          :reported_reason_non_compliant,
          :reported_reason_safe_and_compliant,
          :reported_reason
        )
    end
  end
end
