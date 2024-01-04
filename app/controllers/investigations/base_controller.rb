class Investigations::BaseController < ApplicationController
private

  def set_notification
    @notification_object = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    @notification = @notification_object.decorate
  rescue ActiveRecord::RecordNotFound
    render_404_page
  end

  def authorize_notification_updates
    authorize @notification, :update?
  end

  # TODO: Remove all below once all investigation controllers use notification instead
  def set_investigation
    @investigation_object = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    @investigation = @investigation_object.decorate
  rescue ActiveRecord::RecordNotFound
    render_404_page
  end

  def authorize_investigation_non_protected_details
    authorize @investigation, :view_non_protected_details?
  end

  def authorize_investigation_protected_details
    authorize @investigation, :view_protected_details?
  end

  def authorize_investigation_updates
    authorize @investigation, :update?
  end

  def authorize_investigation_change_owner_or_status
    authorize @investigation, :change_owner_or_status?
  end

  def authorize_investigation_change_visibility
    authorize @investigation, :can_unrestrict?
  rescue Pundit::NotAuthorizedError
    render_404_page
  end
end
