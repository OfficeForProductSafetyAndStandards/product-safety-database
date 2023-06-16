class Investigations::BaseController < ApplicationController
private

  def set_investigation
    @investigation_object = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    @investigation = @investigation_object.decorate
  rescue ActiveRecord::RecordNotFound
    render_404_page
  end

  def authorize_investigation_non_protected_details
    authorize @investigation, :view_non_protected_details?
  end

  def authorize_investigation_updates
    authorize @investigation, :update?
  end

  def authorize_investigation_change_owner_or_status
    authorize @investigation, :change_owner_or_status?
  end
end
