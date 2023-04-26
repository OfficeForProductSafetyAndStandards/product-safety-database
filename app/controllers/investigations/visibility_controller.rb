module Investigations
  class VisibilityController < ApplicationController
    before_action :set_investigation

    def show
      authorize @investigation, :can_unrestrict?
      @last_update_visibility_activity = @investigation.activities.where(type: "AuditActivity::Investigation::UpdateVisibility").order(:created_at).first
    rescue Pundit::NotAuthorizedError
      render_404_page
    end

    def restrict
      authorize @investigation, :can_unrestrict?
      change_case_visibility(new_visibility: "restricted", template: :restrict, flash: "restricted")
    rescue Pundit::NotAuthorizedError
      render_404_page
    end

    def unrestrict
      authorize @investigation, :can_unrestrict?
      change_case_visibility(new_visibility: "unrestricted", template: :unrestrict, flash: "unrestricted")
    rescue Pundit::NotAuthorizedError
      render_404_page
    end

  private

    def set_investigation
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
    end

    def change_case_visibility(new_visibility:, template:, flash:)
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize @investigation, :can_unrestrict?

      @change_case_visibility_form = ChangeCaseVisibilityForm.from(@investigation)
      @change_case_visibility_form.assign_attributes(change_case_visibility_form_params.merge(new_visibility:))

      # If not a PATCH request we should escape now and just display the form.
      if !@change_case_visibility_form.valid? || !request.patch?
        @investigation = @investigation.decorate
        return render(template)
      end

      ChangeCaseVisibility.call!(@change_case_visibility_form.serializable_hash.merge(user: current_user, investigation: @investigation))

      redirect_to investigation_path(@investigation), flash: { success: "Case was #{flash}" }
    end

    def change_case_visibility_form_params
      return {} unless request.patch?

      params.require(:change_case_visibility_form).permit(:rationale)
    end
  end
end
