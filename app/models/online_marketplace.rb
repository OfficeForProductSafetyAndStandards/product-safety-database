class OnlineMarketplace < ApplicationRecord
  has_one :business

  validates :name, presence: true, uniqueness: true
  scope :approved, -> { where(approved_by_opss: true) }
end
