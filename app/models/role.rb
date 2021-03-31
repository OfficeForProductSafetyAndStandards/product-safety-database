class Role < ApplicationRecord
  belongs_to :entity, polymorphic: true
  validates :name, presence: true
  validates :name, uniqueness: { scope: :entity }

  CROWN_DEPENDENCIES_HIDDEN_NOTIFYING_COUNTRY = ([
    "country:GB"
  ] + Country::ADDITIONAL_COUNTRIES.map(&:second)).freeze
end
