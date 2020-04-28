class UserSource < Source
  belongs_to :user, optional: true

  def show
    user.present? ? user.decorate.display_name : "anonymous"
  end

  def user_has_gdpr_access?(user: User.current)
    user.organisation == self.user&.organisation
  end
end
