class Organisation < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify

  validates :name, presence: true

  redacted_export_with :id, :created_at, :name, :updated_at
end
