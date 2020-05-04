class UserRole < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :name, uniqueness: { scope: :user }
end
