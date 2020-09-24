class Investigations::RecordEmailsController < ApplicationController
  def new
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    @correspondence = Correspondence::Email.new

    @investigation = @investigation.decorate
  end

  def create
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    @correspondence = @investigation.emails.new(email_params)

    # TODO: refactor into a service class
    if !@correspondence.email_file.attached? && params[:existing_email_file]
      @correspondence.email_file.attach(params[:existing_email_file])
    end

    # TODO: refactor into a service class
    if !@correspondence.email_attachment.attached? && params[:existing_email_attachment]
      @correspondence.email_attachment.attach(params[:existing_email_attachment])
    end

    # TODO: refactor into model
    @correspondence.set_dates_from_params(params[:correspondence_email])

    if @correspondence.save
      redirect_to investigation_email_path(@investigation.pretty_id, @correspondence)

      update_attachments

      # TODO: refactor into a service class
      AuditActivity::Correspondence::AddEmail.from(@correspondence, @investigation)

    else
      @investigation = @investigation.decorate

      @attachment_description = params[:correspondence_email][:attachment_description]

      render :new
    end
  end

private

  def audit_class
    AuditActivity::Correspondence::AddEmail
  end

  def email_params
    params.require(:correspondence_email).permit(
      :correspondent_name,
      :email_address,
      :email_direction,
      :overview,
      :details,
      :email_subject,
      :email_file,
      :email_attachment
    )
  end

  def update_attachments
    if @correspondence.email_attachment.attached?
      @correspondence.email_attachment.blob.metadata[:description] = params[:correspondence_email][:attachment_description]
      @correspondence.email_attachment.blob.save!
    end
  end
end
