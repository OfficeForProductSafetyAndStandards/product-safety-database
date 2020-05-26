class EditInvestigationCollaboratorForm
  PERMISSION_LEVEL_EDIT = "edit".freeze
  PERMISSION_LEVEL_DELETE = "delete".freeze
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :permission_level
  attribute :message
  attribute :investigation
  attribute :team
  attribute :user
  attribute :include_message, :boolean

  validates_presence_of :permission_level
  validate :select_different_permission_level
  validates :include_message, inclusion: { in: [true, false] }
  validates_presence_of :message,
                        if: -> { include_message }

  def save!
    if valid?
      edit_accesses_collaboration.destroy!
      add_deletion_activity!
      schedule_delete_emails
      true
    else
      false
    end
  end

private

  def edit_accesses_collaboration
    investigation.edit_access_collaborations.find_by!(collaborator_id: team.id)
  end

  def schedule_delete_emails
    schedule_delete_email(find_emails)
  end

  def find_emails
    if team.team_recipient_email.present?
      [team.team_recipient_email]
    else
      team.users.active.pluck(:email)
    end
  end

  def add_deletion_activity!
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
      NotifyMailer.team_deleted_from_case_email(message: message, investigation: investigation, team_deleted: team, user_who_deleted: user, to_email: email).deliver_later
    end
  end
end
