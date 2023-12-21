class Role < ApplicationRecord
  # Only track user roles for now
  has_paper_trail on: %i[create update destroy], only: %i[name], if: ->(t) { t.entity.is_a?(User) }, meta: { entity_type: :entity_type, entity_id: :entity_id }

  belongs_to :entity, polymorphic: true
  validates :name, presence: true
  validates :name, uniqueness: { scope: :entity }

  redacted_export_with :id, :created_at, :entity_id, :entity_type, :name, :updated_at
end
