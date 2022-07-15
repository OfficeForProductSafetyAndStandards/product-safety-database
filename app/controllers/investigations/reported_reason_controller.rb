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
        result = ChangeSafetyAndComplianceData.call!(
          @reported_reason_form.serializable_hash.merge({
            investigation:,
            user: current_user
          })
        )

        flash[:success] = "Case information changed." if result.changes_made

        @investigation = investigation.decorate
        redirect_to investigation_path(@investigation)
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
