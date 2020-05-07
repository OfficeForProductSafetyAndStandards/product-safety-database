class Source < ApplicationRecord
  belongs_to :sourceable, polymorphic: true

  def show(viewing_user = nil)
    nil
  end

  def created_by
    "Created by #{show}, #{created_at.strftime('%d/%m/%Y')}"
  end

  def user_has_gdpr_access?(*)
    true
  end
end
