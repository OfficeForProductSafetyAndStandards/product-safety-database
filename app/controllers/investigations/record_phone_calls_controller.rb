class Investigations::RecordPhoneCallsController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates
  before_action :set_case_breadcrumbs

  def new
    @correspondence_form = PhoneCallCorrespondenceForm.new
  end

  def create
    @correspondence_form = PhoneCallCorrespondenceForm.new(phone_call_params)
    @correspondence_form.cache_file!
    @correspondence_form.load_transcript_file

    return render :new unless @correspondence_form.valid?

    AddPhoneCallToCase.call!(
      @correspondence_form
        .attributes
        .except("existing_transcript_file_id")
        .merge(investigation: @investigation_object, user: current_user)
    )

    redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
  end

  def edit
    phone_call           = Correspondence::PhoneCall.find(params[:id])
    @correspondence_form = PhoneCallCorrespondenceForm.from(phone_call)
    @phone_call          = phone_call.decorate
  end

  def update
    phone_call = Correspondence::PhoneCall.find(params[:id])
    correspondence_form = PhoneCallCorrespondenceForm.new(phone_call_params.merge(id: phone_call.id))
    correspondence_form.cache_file!
    correspondence_form.load_transcript_file

    if correspondence_form.valid?
      UpdatePhoneCall.call!(correspondence_form.attributes.merge(correspondence: phone_call, user: current_user))

      return redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    end

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
