module Investigations
  class SafetyAndComplianceController < ApplicationController
    def edit
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?
      @why_reporting_form = WhyReportingForm.from(@investigation)
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?

      @why_reporting_form = WhyReportingForm.new(why_reporting_form_params)

    end

    def why_reporting_form_params
      params.require(:investigation)
        .permit(
          :hazard_type,
          :hazard_description,
          :non_compliant_reason,
          :reported_reason_unsafe,
          :reported_reason_non_compliant,
          :reported_reason_safe_and_compliant
        )
    end
  end
end
