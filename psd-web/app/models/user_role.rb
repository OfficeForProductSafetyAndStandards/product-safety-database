class UserRole < ApplicationRecord
  belongs_to :user
  validates_presence_of :name
  validates :name, uniqueness: { scope: :user }
end
