module Investigations
  class SafetyAndComplianceController < ApplicationController
    def edit
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      @reported_reason = params[:reported_reason]
      authorize @investigation, :update?
      @why_reporting_form = WhyReportingForm.from(@investigation, @reported_reason)
    end

    def update
      investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize investigation, :update?

      @why_reporting_form = WhyReportingForm.new(why_reporting_form_params)
      if @why_reporting_form.valid?
        result = ChangeSafetyAndComplianceData.call!(
          @why_reporting_form.serializable_hash.merge({
            investigation:,
            user: current_user
          })
        )

        flash[:success] = "Case information changed." if result.changes_made

        @investigation = investigation.decorate
        redirect_to investigation_path(@investigation)
      else
        @investigation = investigation.decorate
        @reported_reason = @why_reporting_form.reported_reason
        render :edit
      end
    end

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
