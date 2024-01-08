module Investigations
  class ReferenceNumbersController < Investigations::BaseController
    before_action :set_notification
    before_action :authorize_notification_updates
    before_action :set_notification_breadcrumbs

    def edit; end

    def update
      if @notification.complainant_reference == reference_number_params[:complainant_reference]
        return redirect_to investigation_path(@notification)
      end

      ChangeNotificationReferenceNumber.call!(notification: @notification, reference_number: reference_number_params[:complainant_reference], user: current_user)
      ahoy.track "Updated reference number", { notification_id: @notification.id }
      redirect_to investigation_path(@notification), flash: { success: "The reference number was updated" }
    end

  private

    def reference_number_params
      params.require(:investigation).permit(:complainant_reference)
    end
  end
end
