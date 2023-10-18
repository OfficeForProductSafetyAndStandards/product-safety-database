class OnlineMarketplace < ApplicationRecord
  belongs_to :business, optional: true

  validates :name, presence: true, uniqueness: true
  scope :approved, -> { where(approved_by_opss: true) }
end
