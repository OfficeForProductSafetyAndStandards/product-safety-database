class Api::V1::NotificationProductsController < Api::BaseController
  before_action :notification
  before_action :product, only: :create

  def create
    send_email = params[:send_email].present? && params[:send_email] == "true"
    interactor = AddProductToNotification.call(
      user: current_user,
      notification: @notification,
      product: @product,
      skip_email: send_email
    )

    if interactor.success?
      render json: { location: api_v1_notification_path(@notification) }, status: :created, location: api_v1_notification_path(@notification)
    else
      render json: { error: interactor.error }, status: :unprocessable_entity
    end
  end

private

  def notification
    @notification ||= Investigation.find_by(pretty_id: params[:notification_id])&.decorate
  end

  def product
    @product ||= Product.find(product_add_params[:id])
  end

  def product_add_params
    params.require(:product).permit(:id)
  end
end
