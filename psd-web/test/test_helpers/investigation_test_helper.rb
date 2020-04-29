module InvestigationTestHelper
  def set_investigation_source!(investigation, user)
    investigation.source.update user_id: user.id
  end

  def set_investigation_owner!(investigation, owner, owner_type = "User")
    investigation.update_columns(owner_id: owner.id, owner_type: owner_type)
  end
end
