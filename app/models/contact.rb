class Contact < ApplicationRecord
  default_scope { order(created_at: :asc) }
  belongs_to :business

  has_one :source, as: :sourceable, dependent: :destroy

  redacted_export_with :id, :business_id, :created_at, :updated_at

  def summary
    [
      name,
      job_title,
      phone_number,
      email
    ].reject(&:blank?).join(", ")
  end
end
