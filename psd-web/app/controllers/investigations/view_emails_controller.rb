class Investigations::ViewEmailsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @email = @investigation.emails.find(params[:id])

    render "investigations/emails/show"
  end
end
