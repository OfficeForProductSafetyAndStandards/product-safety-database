class AuditActivity::Correspondence::EmailUpdated < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::Email"

  def title(_viewing_user = nil)
    correspondence&.overview.presence || "Email"
  end

  def restricted_title(_user)
    "Email"
  end

  def email_id
    metadata["email_id"]
  end

  def new_correspondence_date
    updated_values["correspondence_date"]&.to_date
  end

  def new_email_direction
    updated_values["email_direction"]
  end

  def new_correspondent_name
    updated_values["correspondent_name"]
  end

  def new_email_address
    updated_values["email_address"]
  end

  def new_overview
    updated_values["overview"]
  end

  def new_details
    updated_values["details"]
  end

  def email_file_changed?
    updated_values.key?("email_filename")
  end

  def new_email_file
    updated_values["email_filename"]
  end

  def new_email_subject
    updated_values["email_subject"]
  end

  def email_attachment_changed?
    updated_values.key?("email_attachment_filename")
  end

  def new_email_attachment
    updated_values["email_attachment_filename"]
  end

  def new_attachment_description
    updated_values["attachment_description"]
  end

  def self.build_metadata(email:, email_changed:, previous_email_filename:, email_attachment_changed:, previous_email_attachment_filename:, previous_attachment_description:)
    updates = email.previous_changes.slice(
      :correspondence_date,
      :correspondent_name,
      :details,
      :email_address,
      :email_direction,
      :email_subject,
      :overview,
      :email_direction,
      :name
    )

    if email_changed
      updates[:email_filename] = [previous_email_filename, email.email_file&.try(:filename)]
    end

    if email_attachment_changed
      updates[:email_attachment_filename] = [previous_email_attachment_filename, email.email_attachment.try(:filename)]
    end

    new_email_attachment_description = email.email_attachment.try(:metadata).to_h["description"].to_s

    if previous_attachment_description.to_s != new_email_attachment_description.to_s
      updates[:attachment_description] = [previous_attachment_description, new_email_attachment_description]
    end

    {
      email_id: email.id,
      updates:
    }
  end

private

  def subtitle_slug
    "Email updated"
  end

  def updated_values
    @updated_values ||= metadata["updates"].transform_values(&:second)
  end
end
