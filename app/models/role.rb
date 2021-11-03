class Role < ApplicationRecord
  belongs_to :entity, polymorphic: true
  validates :name, presence: true
  validates :name, uniqueness: { scope: :entity }

  redacted_export_with :id, :created_at, :entity_id, :entity_type, :name, :updated_at
end
