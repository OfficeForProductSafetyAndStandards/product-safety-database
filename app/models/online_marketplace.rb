class OnlineMarketplace < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  scope :approved, -> { where(approved_by_opss: true) }
end
