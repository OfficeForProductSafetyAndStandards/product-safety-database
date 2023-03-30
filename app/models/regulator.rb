class Regulator < ApplicationRecord
  has_many :organisations
  has_many :teams, through: :organisations
end
