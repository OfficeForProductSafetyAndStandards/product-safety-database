class Source < ApplicationRecord
  belongs_to :sourceable, polymorphic: true

  redacted_export_with :id, :created_at, :name, :sourceable_id, :sourceable_type, :type,
                       :updated_at, :user_id

  def show(*)
    nil
  end

  def created_by
    "Created by #{show}, #{created_at.strftime('%d/%m/%Y')}"
  end
end
