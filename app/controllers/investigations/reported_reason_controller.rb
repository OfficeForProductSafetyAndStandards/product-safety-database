module Investigations
  class ReportedReasonController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def edit
      @reported_reason_form = ReportedReasonForm.from(@investigation)
    end

    def update
      @reported_reason_form = ReportedReasonForm.new(reported_reason:)

      if @reported_reason_form.valid?
        result = ChangeReportedReason.call!(
          @reported_reason_form.serializable_hash.merge({
            investigation: @investigation,
            user: current_user
          })
        )

        if @reported_reason_form.reported_reason == "safe_and_compliant"
          flash[:success] = "The case information was updated" if result.changes_made
          redirect_to investigation_path(@investigation)
        else
          redirect_to edit_investigation_safety_and_compliance_path(@investigation, reported_reason: @reported_reason_form.reported_reason)
        end
      else
        render :edit
      end
    end

  private

    def reported_reason_form_params
      params.permit(
        investigation: [:reported_reason]
      )
    end

    def reported_reason
      reported_reason_form_params.dig(:investigation, :reported_reason)
    end
  end
end
