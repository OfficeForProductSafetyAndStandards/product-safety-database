class Role < ApplicationRecord
  belongs_to :entity, polymorphic: true
  validates :name, presence: true
  validates :name, uniqueness: { scope: :entity }
end
