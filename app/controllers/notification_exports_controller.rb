class NotificationExportsController < ApplicationController
  include InvestigationsHelper

  def generate
    authorize Investigation, :export?

    notification_export = NotificationExport.create!(params: notification_export_params, user: current_user)
    NotificationExportJob.perform_later(notification_export)
    redirect_to notifications_path(q: params[:q]), flash: { success: "Your notification export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Investigation, :export?

    @notification_export = NotificationExport.find_by!(id: params[:id], user: current_user)
  end
end
