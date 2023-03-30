class Organisation < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify
  belongs_to :ts_region, optional: true
  belongs_to :regulator, optional: true

  validates :name, presence: true

  redacted_export_with :id, :created_at, :name, :updated_at
end
