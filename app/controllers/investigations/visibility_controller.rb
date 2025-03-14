module Investigations
  class VisibilityController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_change_visibility
    before_action :set_investigation_breadcrumbs

    def show
      @last_update_visibility_activity = @investigation.activities.where(type: "AuditActivity::Investigation::UpdateVisibility").order(:created_at).first
    end

    def restrict
      change_case_visibility(new_visibility: "restricted", template: :restrict, flash: "restricted")
    end

    def unrestrict
      change_case_visibility(new_visibility: "unrestricted", template: :unrestrict, flash: "unrestricted")
    end

  private

    def change_case_visibility(new_visibility:, template:, flash:)
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize @investigation, :can_unrestrict?

      @change_notification_visibility_form = ChangeNotificationVisibilityForm.from(@investigation)
      @change_notification_visibility_form.assign_attributes(change_notification_visibility_form_params.merge(new_visibility:))

      # If not a PATCH request we should escape now and just display the form.
      if !@change_notification_visibility_form.valid? || !request.patch?
        @investigation = @investigation.decorate
        return render(template)
      end

      ChangeNotificationVisibility.call!(@change_notification_visibility_form.serializable_hash.merge(user: current_user, notification: @investigation))

      redirect_to investigation_path(@investigation), flash: { success: "Notification was #{flash}" }
    end

    def change_notification_visibility_form_params
      return {} unless request.patch?

      params.require(:change_notification_visibility_form).permit(:rationale)
    end
  end
end
