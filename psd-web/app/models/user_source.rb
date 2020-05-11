class UserSource < Source
  belongs_to :user, optional: true

  def show(viewer = nil)
    user.present? ? user.decorate.display_name(viewer: viewer) : "anonymous"
  end

  def user_has_gdpr_access?(user: User.current)
    user.organisation == self.user&.organisation
  end
end
