class Investigations::RecordPhoneCallsController < ApplicationController
  def new
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @correspondence_form = PhoneCallCorrespondenceForm.new
    @investigation = investigation.decorate
  end

  def create
    @correspondence_form = PhoneCallCorrespondenceForm.new(phone_call_params)
    @correspondence = Correspondence::PhoneCall.new(@correspondence_form.attributes)
    @correspondence.save!

    return render :new unless @correspondence_form.valid?

    redirect_to @correspondence
  end

private

  def phone_call_params
    params.require(:phone_call_correspondence_form).permit(
      :correspondent_name,
      :phone_number,
      :overview,
      :details,
      :correspondence_date,
      transcript: []
    )
  end
end
