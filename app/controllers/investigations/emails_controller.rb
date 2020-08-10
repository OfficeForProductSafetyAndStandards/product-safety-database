class Investigations::EmailsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_protected_details?
    @email = @investigation.emails.find(params[:id]).decorate
  end
end
