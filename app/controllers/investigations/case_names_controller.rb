module Investigations
  class CaseNamesController < Investigations::BaseController
    before_action :set_notification
    before_action :authorize_notification_updates
    before_action :set_notification_breadcrumbs

    def edit
      @notification_name_form = ChangeNotificationNameForm.new(user_title: @notification.user_title, current_user:)
    end

    def update
      @notification_name_form = ChangeNotificationNameForm.new(case_name_params.merge(current_user:))

      if @notification_name_form.valid?
        ChangeNotificationName.call!(notification: @notification, user_title: @notification_name_form.user_title, user: current_user)
        ahoy.track "Updated notification name", { notification_id: @notification.id }
        redirect_to investigation_path(@notification), flash: { success: "The notification name was updated" }
      else
        render :edit
      end
    end

  private

    def case_name_params
      params.require(:investigation).permit(:user_title)
    end
  end
end
