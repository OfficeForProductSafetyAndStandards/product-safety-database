module Investigations
  class StatusController < ApplicationController
    def close
      change_case_status(new_status: "closed", template: :close, flash: "closed")
    end

    def reopen
      change_case_status(new_status: "open", template: :reopen, flash: "re-opened")
    end

  private

    def change_case_status(new_status:, template:, flash:)
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :change_owner_or_status?
      return redirect_to cannot_close_investigation_path(investigation) if policy(investigation).can_be_deleted? && new_status == "closed"

      @change_case_status_form = ChangeCaseStatusForm.from(investigation)
      @change_case_status_form.assign_attributes(change_case_status_form_params.merge(new_status:))

      # If not a PATCH request we should escape now and just display the form.
      if !@change_case_status_form.valid? || !request.patch?
        @investigation = investigation.decorate
        return render(template)
      end

      ChangeCaseStatus.call!(@change_case_status_form.serializable_hash.merge(user: current_user, investigation:))

      redirect_to investigation_path(investigation), flash: { success: "The case was #{flash}" }
    end

    def change_case_status_form_params
      return {} unless request.patch?

      params.require(:change_case_status_form).permit(:rationale)
    end
  end
end
