class Organisation < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify

  validates :name, presence: true
end
