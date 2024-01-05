class EditNotificationCollaboratorForm
  PERMISSION_LEVEL_DELETE = "delete".freeze
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :collaboration
  attribute :permission_level
  attribute :message
  attribute :include_message, :boolean

  validates_presence_of :collaboration
  validates_presence_of :permission_level
  validate :permission_level_valid?, if: -> { collaboration.present? && !delete? }
  validate :select_different_permission_level, if: -> { collaboration.present? }
  validates :include_message, inclusion: { in: [true, false] }
  validates_presence_of :message, allow_blank: false, if: -> { include_message }

  def permission_level
    attributes["permission_level"] || existing_permission_level
  end

  def delete?
    permission_level == PERMISSION_LEVEL_DELETE
  end

  def new_collaboration_class
    Collaboration::Access.class_from_human_name(permission_level)
  end

private

  def permission_level_valid?
    errors.add(:permission_level, :blank) if new_collaboration_class.blank?
  end

  def select_different_permission_level
    if permission_level == existing_permission_level
      errors.add(:permission_level, :select_different_permission_level)
    end
  end

  def existing_permission_level
    collaboration.model_name.human
  end
end
