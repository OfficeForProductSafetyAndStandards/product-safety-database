class Api::V1::NotificationsController < Api::BaseController
  include Pagy::Backend
  before_action :notification, only: :show

  def show; end

private

  def notification
    @notification ||= Investigation.find_by(pretty_id: params[:id])&.decorate

    return render json: { error: "Notification not found" }, status: :not_found if @notification.blank?
  end
end
