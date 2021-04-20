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

      @change_case_status_form = ChangeCaseStatusForm.new(change_case_status_form_params.merge(new_status: new_status))

      if !@change_case_status_form.valid? || !request.patch?
        @investigation = investigation.decorate
        return render template
      end

      ChangeCaseStatus.call!(@change_case_status_form.serializable_hash.merge(user: current_user, investigation: investigation))

      redirect_to investigation_path(investigation), flash: { success: "#{investigation.case_type.upcase_first} was #{flash}" }
    end

    def change_case_status_form_params
      return {} unless request.patch?

      params.require(:change_case_status_form).permit(:rationale)
    end
  end
end
