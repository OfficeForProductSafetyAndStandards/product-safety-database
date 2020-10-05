class Investigations::RecordPhoneCallsController < ApplicationController

  def new
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @correspondence = Correspondence::PhoneCall.new
    @investigation = investigation.decorate
  end

  def create

  end

private

  def phone_call_params
    params.require(:correspondence_phone_call).permit(
      :correspondent_name,
      :phone_number,
      :overview,
      :details,
      :correspondence_date,
      transcript: []
    )
  end
end
