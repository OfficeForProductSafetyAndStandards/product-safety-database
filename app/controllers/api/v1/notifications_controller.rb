class Api::V1::NotificationsController < Api::BaseController
  include Pagy::Backend
  before_action :notification, only: :show

  def show; end

  def create
    @notification = Investigation::Notification.new(notification_create_params)
    @notification.state = "draft"
    CreateNotification.call!(notification: @notification, user: current_user, from_task_list: true, silent: true)

    @notification.tasks_status["search_for_or_add_a_product"] = "in_progress"
    @notification.save!(context: :search_for_or_add_a_product)

    render action: :show
  end

private

  def notification_create_params
    params.require(:notification).permit(
      :user_title, :complainant_reference, :reported_reason,
      :hazard_type, :hazard_description, :non_compliant_reason
    )
  end

  def notification
    @notification ||= Investigation.find_by(pretty_id: params[:id])&.decorate

    return render json: { error: "Notification not found" }, status: :not_found if @notification.blank?
  end
end
