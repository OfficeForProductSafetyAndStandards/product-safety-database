class Investigations::RecordPhoneCallsController < ApplicationController
  def new
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @correspondence_form = PhoneCallCorrespondenceForm.new
    @investigation = investigation.decorate
  end

  def create
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @correspondence_form = PhoneCallCorrespondenceForm.new(phone_call_params)
    @correspondence = investigation.phone_calls.new(@correspondence_form.attributes)

    @investigation = investigation.decorate

    return render :new unless @correspondence_form.valid?

    @correspondence.save!

    redirect_to investigation_phone_call_path(@investigation.pretty_id, @correspondence.id)
  end

private

  def phone_call_params
    params.require(:phone_call_correspondence_form).permit(
      :correspondent_name,
      :phone_number,
      :overview,
      :details,
      :transcript,
      correspondence_date: %i[day month year]
    )
  end
end
