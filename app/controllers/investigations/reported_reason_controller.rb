module Investigations
  class ReportedReasonController < ApplicationController
    def edit
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?
      @reported_reason_form = ReportedReasonForm.from(@investigation)
    end

    def update
      investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize investigation, :update?

      @reported_reason_form = ReportedReasonForm.new(reported_reason_form_params)

      if @reported_reason_form.valid?
        result = ChangeReportedReason.call!(
          @reported_reason_form.serializable_hash.merge({
            investigation:,
            user: current_user
          })
        )

        if @reported_reason_form.reported_reason == "safe_and_compliant"
          flash[:success] = "The case information was updated" if result.changes_made

          @investigation = investigation.decorate
          redirect_to investigation_path(@investigation)
        else
          @investigation = investigation.decorate
          redirect_to edit_investigation_safety_and_compliance_path(@investigation, reported_reason: @reported_reason_form.reported_reason)
        end
      else
        @investigation = investigation.decorate
        render :edit
      end
    end

    def reported_reason_form_params
      params.require(:investigation)
        .permit(
          :reported_reason
        )
    end
  end
end
