class Investigations::RecordPhoneCallsController < Investigations::CorrespondenceController
  set_attachment_names :transcript
  set_file_params_key :correspondence_phone_call

private

  def audit_class
    AuditActivity::Correspondence::AddPhoneCall
  end

  def model_class
    Correspondence::PhoneCall
  end

  def file_metadata
    get_attachment_metadata_params(:transcript).merge(
      title: correspondence_params["overview"],
      description: "Call transcript"
    )
  end

  def request_params
    return {} if params[correspondence_params_key].blank?

    params.require(correspondence_params_key).permit(
      :correspondent_name,
      :phone_number,
      :overview,
      :details
    )
  end

  def set_attachments
    @transcript_blob, * = load_file_attachments
  end

  def update_attachments
    update_blob_metadata @transcript_blob, file_metadata
  end

  def correspondence_valid?
    @correspondence.validate(step || steps.last)
    @correspondence.validate_transcript_and_content(@transcript_blob) if step == :content
    validate_blob_size(@transcript_blob, @correspondence.errors, "file")
    @correspondence.errors.empty?
  end

  def attach_files
    attach_blob_to_attachment_slot(@transcript_blob, @correspondence.transcript)
  end
end
