module InvestigationTestHelper
  def set_investigation_source!(investigation, user)
    investigation.source.update user_id: user.id
  end

  def set_investigation_owner!(investigation, assignee, owner_type = "User")
    investigation.update_columns(owner_id: assignee.id, owner_type: owner_type)
  end
end
