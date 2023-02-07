class Contact < ApplicationRecord
  default_scope { order(created_at: :asc) }
  belongs_to :business
  belongs_to :added_by_user, class_name: :User, optional: true

  redacted_export_with :id, :added_by_user_id, :business_id, :created_at,
                       :updated_at

  def summary
    [
      name,
      job_title,
      phone_number,
      email
    ].reject(&:blank?).join(", ")
  end
end
