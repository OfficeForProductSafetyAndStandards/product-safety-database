class AddEmailToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :user, :email, :correspondence_date, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file, :email_attachment, :attachment_description, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.email = investigation.emails.create!(
      correspondent_name: correspondent_name,
      correspondence_date: correspondence_date,
      email_address: email_address,
      email_direction: email_direction,
      overview: overview,
      details: details,
      email_subject: email_subject,
      email_file: email_file,
      email_attachment: email_attachment
    )

    if email.email_attachment.attached? && attachment_description.present?
      update_attachment_description!
    end

    create_audit_activity(email, investigation)

    send_notification_email(investigation, user)

    # TODO: refactor into this class
    # AuditActivity::Correspondence::AddEmail.from(email, investigation)
  end

private

  def create_audit_activity(correspondence, investigation)
    activity = AuditActivity::Correspondence::AddEmail.create!(
      body: build_body(correspondence) || sanitize_text(correspondence.details),
      source: UserSource.new(user: User.current),
      investigation: investigation,
      title: correspondence.overview,
      correspondence: correspondence
    )

    activity.attach_blob(correspondence.email_file.blob, :email_file) if correspondence.email_file.attached?
    activity.attach_blob(correspondence.email_attachment.blob, :email_attachment) if correspondence.email_attachment.attached?
  end

  def build_body(correspondence)
    body = ""
    body += build_correspondent_details correspondence
    body += "Subject: **#{sanitize_text correspondence.email_subject}**<br>" if correspondence.email_subject.present?
    body += "Date sent: **#{correspondence.correspondence_date.strftime('%d/%m/%Y')}**<br>" if correspondence.correspondence_date.present?
    body += build_email_file_body correspondence
    body += build_attachment_body correspondence
    body += "<br>#{sanitize_text correspondence.details}" if correspondence.details.present?
    body
  end

  def build_correspondent_details(correspondence)
    return "" unless correspondence.correspondent_name || correspondence.email_address

    output = ""
    output += "#{Correspondence::Email.email_directions[correspondence.email_direction]}: " if correspondence.email_direction.present?
    output += "**#{sanitize_text correspondence.correspondent_name}** " if correspondence.correspondent_name.present?
    output += build_email_address correspondence if correspondence.email_address.present?
    output
  end

  def build_email_file_body(correspondence)
    file = correspondence.email_file
    file.attached? ? "Email: #{sanitize_text file.filename}<br>" : ""
  end

  def build_attachment_body(correspondence)
    file = correspondence.email_attachment
    file.attached? ? "Attached: #{sanitize_text file.filename}<br>" : ""
  end

  def build_email_address(correspondence)
    output = ""
    output += "(" if correspondence.correspondent_name.present?
    output += sanitize_text correspondence.email_address
    output += ")" if correspondence.correspondent_name.present?
    output + "<br>"
  end

  def sanitize_text(text)
    return text.to_s.strip.gsub(/[*_~]/) { |match| "\\#{match}" } if text
  end

  def update_attachment_description!
    context.email.email_attachment.blob.metadata[:description] = attachment_description
    context.email.email_attachment.blob.save!
  end

  def source
    UserSource.new(user: user)
  end

  def send_notification_email(investigation, _user)
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_update_text(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_update_text(viewer = nil)
    "Email details added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end
end
