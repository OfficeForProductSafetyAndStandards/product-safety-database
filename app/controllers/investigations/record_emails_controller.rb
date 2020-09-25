class Investigations::RecordEmailsController < ApplicationController
  def new
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    @email_correspondence_form = EmailCorrespondenceForm.new

    @investigation = @investigation.decorate
  end

  def create
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    @email_correspondence_form = EmailCorrespondenceForm.new
    @email_correspondence_form.attributes = email_correspondence_form_params

    if @email_correspondence_form.email_file.present? && @email_correspondence_form.existing_email_file_id.blank?

      @email_correspondence_form.email_file = ActiveStorage::Blob.create_after_upload!(
        io: @email_correspondence_form.email_file,
        filename: @email_correspondence_form.email_file.original_filename,
        content_type: @email_correspondence_form.email_file.content_type
      )

      @email_correspondence_form.existing_email_file_id = @email_correspondence_form.email_file.signed_id

    elsif @email_correspondence_form.existing_email_file_id.present? && @email_correspondence_form.email_file.blank?

      @email_correspondence_form.email_file = ActiveStorage::Blob.find_signed(@email_correspondence_form.existing_email_file_id)

    end

    if @email_correspondence_form.email_attachment.present? && @email_correspondence_form.existing_email_attachment_id.blank?

      @email_correspondence_form.email_attachment = ActiveStorage::Blob.create_after_upload!(
        io: @email_correspondence_form.email_attachment,
        filename: @email_correspondence_form.email_attachment.original_filename,
        content_type: @email_correspondence_form.email_attachment.content_type
      )

      @email_correspondence_form.existing_email_attachment_id = @email_correspondence_form.email_attachment.signed_id

    elsif @email_correspondence_form.email_attachment.blank? && @email_correspondence_form.existing_email_attachment_id.present?

      @email_correspondence_form.email_attachment = ActiveStorage::Blob.find_signed(@email_correspondence_form.existing_email_attachment_id)

    end

    if @email_correspondence_form.valid?

      result = AddEmailToCase.call(
        @email_correspondence_form.attributes.except(
          "existing_email_file_id",
          "existing_email_attachment_id"
        ).merge({
          investigation: @investigation,
          user: current_user
        })
      )

      redirect_to investigation_email_path(@investigation.pretty_id, result.email)
    else
      @investigation = @investigation.decorate

      render :new
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
      :existing_email_attachment_id,
      :existing_email_file_id,
      correspondence_date: %i[day month year]
    )
  end
end
