class Investigations::RecordEmailsController < ApplicationController
  def new
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :update?

    @email_correspondence_form = EmailCorrespondenceForm.new

    @email = @investigation.emails.new

    @investigation = @investigation.decorate
  end

  def create
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :update?

    @email_correspondence_form = EmailCorrespondenceForm.new(email_correspondence_form_params)

    if @email_correspondence_form.valid?

      AddEmailToCase.call!(
        @email_correspondence_form.attributes.except(
          "email_file_id",
          "email_attachment_id"
        ).merge({
          email_file: @email_correspondence_form.email_file || @email_correspondence_form.cached_email_file,
          email_attachment: @email_correspondence_form.email_attachment || @email_correspondence_form.cached_email_attachment,
          investigation: @investigation,
          user: current_user
        })
      )

      redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    else

      @email = @investigation.emails.new
      @email_correspondence_form.cache_files!

      @email_correspondence_form.email_file_action = "keep" if @email_correspondence_form.email_file.present?
      @email_correspondence_form.email_attachment_action = "keep" if @email_correspondence_form.email_attachment.present?

      @investigation = @investigation.decorate

      render :new
    end
  end

  def edit
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :update?

    @email = @investigation.emails.find(params[:id])
    @email_correspondence_form = EmailCorrespondenceForm.from(@email)

    @investigation = @investigation.decorate
  end

  def update
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :update?

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
      @investigation = @investigation.decorate
      @email_correspondence_form.cache_files!

      render :edit
    end
  end

private

  def email_correspondence_form_params
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
      :email_attachment_action,
      correspondence_date: %i[day month year]
    )
  end
end
