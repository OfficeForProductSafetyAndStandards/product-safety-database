class EditInvestigationCollaboratorForm
  PERMISSION_LEVEL_EDIT = "edit".freeze
  PERMISSION_LEVEL_DELETE = "delete".freeze
  include ActiveModel::Model

  attr_accessor :permission_level, :message, :investigation, :team, :user
  attr_reader :include_message

  validates_presence_of :permission_level
  validate :select_different_permission_level
  validates :include_message, inclusion: { in: [true, false] }
  validates_presence_of :message,
                        if: -> { include_message }

  def save
    if valid?
      collaborator.delete
      schedule_delete_emails
      add_deletion_activity
      true
    else
      false
    end
  end

  def include_message=(value)
    @include_message = if value.is_a? String
                         (value == "true")
                       else
                         value
                       end
  end

private

  def collaborator
    investigation.collaborators.find_by!(team_id: team.id)
  end

  def schedule_delete_emails
    emails = if team.team_recipient_email.present?
               [team.team_recipient_email]
             else
               team.users.active.pluck(:email)
             end
    schedule_delete_email(emails)
  end

  def add_deletion_activity
    AuditActivity::Investigation::TeamDeleted.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: "#{team.name} removed from #{investigation.case_type.downcase}",
      body: message.to_s
    )
  end

  def select_different_permission_level
    if permission_level == EditInvestigationCollaboratorForm::PERMISSION_LEVEL_EDIT
      errors.add(:permission_level, :select_different_permission_level)
    end
  end

  def schedule_delete_email(emails)
    emails.each do |email|
      NotifyMailer.team_deleted_from_case_email(email_payload, to_email: email).deliver_later
    end
  end

  def email_payload
    { permission_level: permission_level, include_message: include_message, message: message, investigation: investigation, team: team, user: user }
  end
end
