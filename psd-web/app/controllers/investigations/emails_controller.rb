class Investigations::EmailsController < Investigations::CorrespondenceController
  set_file_params_key :correspondence_email
  set_attachment_names :email_file, :email_attachment
  skip_before_action :set_correspondence, only: [:show, :create]
  skip_before_action :store_correspondence, only: :create

  def show
    @correspondence = @investigation.correspondence_emails.build(session_params)
    render_wizard
  end

  def update
    @correspondence = @investigation.correspondence_emails.find_or_initialize_by(session_params)
    pp correspondence_email_params
    @correspondence.assign_attributes(correspondence_email_params)
    @correspondence.save!
    byebug
    if @correspondence.email_file.attached?

    end
    pp @correspondence
    super
  end

  def create
    @correspondence = @investigation.correspondence_emails.build(session_params)
    super
  end

private

  def session_params
    session[:correspondence_email] || {}
  end

  def audit_class
    AuditActivity::Correspondence::AddEmail
  end

  def model_class
    Correspondence::Email
  end

  def common_file_metadata
    {
        title: session_params["overview"],
        has_consumer_info: session_params["has_consumer_info"]
    }
  end

  def email_file_metadata
    get_attachment_metadata_params(:email_file)
        .merge(common_file_metadata)
        .merge(
          description: "Original email as a file"
        )
  end

  def email_attachment_metadata
    get_attachment_metadata_params(:email_attachment)
        .merge(common_file_metadata)
  end

  def correspondence_email_params
    params.require(:correspondence_email).permit(
      :correspondence_date,
      :correspondent_name,
      :email_address,
      :email_attachment,
      :email_direction,
      :overview,
      :details,
      :email_subject,
      :attachment_description,
      :has_consumer_info,
      :type
    )
  end

  def set_correspondence
    @correspondence = @investigation.correspondence_emails.build(session_params)
  end

  def set_attachments
    # @email_file_blob, @email_attachment_blob = load_file_attachments
  end

  def update_attachments
    # update_blob_metadata @email_file_blob, email_file_metadata
    # update_blob_metadata @email_attachment_blob, email_attachment_metadata
  end

  def correspondence_valid?
    @correspondence.validate(step || steps.last)
    @correspondence.validate_email_file_and_content(@email_file_blob) if step == :content
    validate_blob_size(@email_file_blob, @correspondence.errors, "email file")
    validate_blob_size(@email_attachment_blob, @correspondence.errors, "email attachment")
    Rails.logger.error "#{__method__}: correspondence has errors: #{@correspondence.errors.full_messages}" if @correspondence.errors.any?
    @correspondence.errors.empty?
  end

  def attach_files
    attach_blob_to_attachment_slot(@email_file_blob, @correspondence.email_file)
    attach_blob_to_attachment_slot(@email_attachment_blob, @correspondence.email_attachment)
    attach_blobs_to_list(@email_file_blob, @email_attachment_blob, @investigation.documents)
  end

  def save_attachments
    @email_file_blob.save if @email_file_blob
    @email_attachment_blob.save if @email_attachment_blob
  end
end
