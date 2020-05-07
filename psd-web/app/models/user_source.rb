class UserSource < Source
  belongs_to :user, optional: true

  def show(viewing_user = nil)
    user.present? ? user.decorate.display_name(other_user: viewing_user) : "anonymous"
  end

  def user_has_gdpr_access?(user: User.current)
    user.organisation == self.user&.organisation
  end
end
