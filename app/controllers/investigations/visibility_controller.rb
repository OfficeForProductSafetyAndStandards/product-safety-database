module Investigations
  class VisibilityController < ApplicationController
    def restrict
      byebug
      change_case_visibility(new_visibility: "restrict", template: :restrict, flash: "closed")
    end

    def unrestrict
      change_case_visibility(new_visibility: "unrestrict", template: :unrestrict, flash: "re-opened")
    end

  private

    def change_case_visibility(new_visibility:, template:, flash:)
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize @investigation, :change_owner_or_status?

      @change_case_visibility_form = ChangeCaseVisibilityForm.from(@investigation)
      @change_case_visibility_form.assign_attributes(change_case_visibility_form_params.merge(new_visibility: new_visibility))

      # If not a PATCH request we should escape now and just display the form.
      if !@change_case_visibility_form.valid? || !request.patch?
        @investigation = @investigation.decorate
        byebug
        return render(template)
      end

      ChangeCaseVisibility.call!(@change_case_visibility_form.serializable_hash.merge(user: current_user, investigation: @investigation))

      redirect_to investigation_path(@investigation), flash: { success: "#{@investigation.case_type.upcase_first} was #{flash}" }
    end

    def change_case_visibility_form_params
      return {} unless request.patch?

      params.require(:change_case_visibility_form).permit(:rationale)
    end
  end
end
