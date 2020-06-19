class UserSource < Source
  belongs_to :user, optional: true

  def show(viewer = nil)
    user.present? ? user.decorate.display_name(viewer: viewer) : "anonymous"
  end
end
