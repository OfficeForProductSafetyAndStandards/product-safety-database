class Investigations::RecordEmailsController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates
  before_action :set_investigation_breadcrumbs

  def new
    @email_correspondence_form = EmailCorrespondenceForm.new
    @email = @investigation_object.emails.new
  end

  def create
    @email_correspondence_form = EmailCorrespondenceForm.new(email_correspondence_form_params)

    if @email_correspondence_form.valid?
      AddEmailToNotification.call!(
        @email_correspondence_form.attributes.except(
          "email_file_id",
          "email_attachment_id"
        ).merge({
          email_file: @email_correspondence_form.email_file || @email_correspondence_form.cached_email_file,
          email_attachment: @email_correspondence_form.email_attachment || @email_correspondence_form.cached_email_attachment,
          notification: @investigation_object,
          user: current_user
        })
      )

      redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    else
      @email = @investigation.emails.new
      @email_correspondence_form.cache_files!

      @email_correspondence_form.email_file_action = "keep" if @email_correspondence_form.email_file.present?
      @email_correspondence_form.email_attachment_action = "keep" if @email_correspondence_form.email_attachment.present?

      render :new
    end
  end

  def edit
    @email = @investigation_object.emails.find(params[:id])
    @email_correspondence_form = EmailCorrespondenceForm.from(@email)
  end

  def update
    @email = @investigation.emails.find(params[:id])
    @email_correspondence_form = EmailCorrespondenceForm.new(email_correspondence_form_params.merge(id: @email.id))

    if @email_correspondence_form.valid?
      UpdateEmail.call!(
        @email_correspondence_form.attributes.merge({
          email: @email,
          user: current_user
        })
      )

      redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    else
      @email_correspondence_form.cache_files!
      render :edit
    end
  end

private

  def email_correspondence_form_params
    email_params = params[:email_correspondence_form]
    date = Date.new(email_params["correspondence_date(1i)"].to_i, email_params["correspondence_date(2i)"].to_i, email_params["correspondence_date(3i)"].to_i) if email_params["correspondence_date(1i)"] != "" && email_params["correspondence_date(2i)"] != "" && email_params["correspondence_date(3i)"] != nil
    params.require(:email_correspondence_form).permit(
      :correspondent_name,
      :email_address,
      :email_direction,
      :overview,
      :details,
      :email_subject,
      :email_file,
      :email_attachment,
      :attachment_description,
      :email_attachment_id,
      :email_file_id,
      :email_file_action,
      :email_attachment_action
    ).merge(correspondence_date: date)
  end
end
