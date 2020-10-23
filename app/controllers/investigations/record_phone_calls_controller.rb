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
    @correspondence_form.cache_file!
    @correspondence_form.load_transcript_file

    @investigation = investigation.decorate

    return render :new unless @correspondence_form.valid?

    result = AddPhoneCallToCase.call!(
      @correspondence_form
        .attributes
        .except("existing_transcript_file_id")
        .merge(investigation: investigation, user: current_user)
    )

    redirect_to investigation_phone_call_path(@investigation.pretty_id, result.correspondence)
  end

  def edit
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    phone_call           = Correspondence::PhoneCall.find(params[:id])
    @correspondence_form = PhoneCallCorrespondenceForm.from(phone_call)
    @investigation       = investigation.decorate
    @phone_call          = phone_call.decorate
  end

  def update
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    phone_call = Correspondence::PhoneCall.find(params[:id])
    correspondence_form = PhoneCallCorrespondenceForm.new(phone_call_params.merge(id: phone_call.id))
    correspondence_form.cache_file!
    correspondence_form.load_transcript_file

    if correspondence_form.valid?
      result = UpdatePhoneCall.call(correspondence_form.attributes.merge(correspondence: phone_call, user: current_user))

      return redirect_to investigation_phone_call_path(investigation, phone_call) if result.success?
    end

    @investigation       = investigation.decorate
    @phone_call          = phone_call.decorate
    @correspondence_form = correspondence_form

    render :edit
  end

private

  def phone_call_params
    params.require(:phone_call_correspondence_form).permit(
      :correspondent_name,
      :phone_number,
      :overview,
      :details,
      :transcript,
      :existing_transcript_file_id,
      correspondence_date: %i[day month year]
    )
  end
end
