module Investigations
  class StatusController < Investigations::BaseController
    before_action :set_investigation
    before_action :set_investigation_breadcrumbs

    def close
      change_notification_status(new_status: "closed", template: :close, flash: "closed")
    end

    def reopen
      change_notification_status(new_status: "open", template: :reopen, flash: "re-opened")
    end

  private

    def change_notification_status(new_status:, template:, flash:)
      authorize @investigation, :change_owner_or_status?
      return redirect_to cannot_close_investigation_path(@investigation) if policy(@investigation).can_be_deleted? && new_status == "closed"

      @change_notification_status_form = ChangeNotificationStatusForm.from(@investigation)
      @change_notification_status_form.assign_attributes(change_notification_status_form_params.merge(new_status:))

      # If not a PATCH request we should escape now and just display the form.
      if !@change_notification_status_form.valid? || !request.patch?
        @investigation = @investigation.decorate
        return render(template)
      end

      ahoy.track "Updated notification status", { notification_id: @investigation.id }
      ChangeNotificationStatus.call!(@change_notification_status_form.serializable_hash.merge(user: current_user, notification: @investigation))

      redirect_to investigation_path(@investigation), flash: { success: "The notification was #{flash}" }
    end

    def change_notification_status_form_params
      return {} unless request.patch?

      params.require(:change_notification_status_form).permit(:rationale)
    end
  end
end
