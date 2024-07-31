module NotificationsHelper
  def show_edit_link?
    policy(@notification).update?(user: current_user)
  end

  def collaborator_access(collaborator)
    case collaborator.to_s
    when Collaboration::Access::Edit.to_s
      "Edit"
    when Collaboration::Access::ReadOnly.to_s
      "View"
    end
  end
end
