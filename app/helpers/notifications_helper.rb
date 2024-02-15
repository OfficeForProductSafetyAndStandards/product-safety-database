module NotificationsHelper
  def show_edit_link?
    policy(@notification).update?(user: current_user)
  end

  def collaborator_access(collaborator)
    case collaborator
    when Collaboration::Access::Edit
      "Edit"
    when Collaboration::Access::ReadOnly
      "View"
    end
  end
end
