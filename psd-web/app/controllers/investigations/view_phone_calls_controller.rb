class Investigations::ViewPhoneCallsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_protected_details?
    @phone_call = @investigation.phone_calls.find(params[:id]).decorate

    render "investigations/phone_calls/show"
  end
end
