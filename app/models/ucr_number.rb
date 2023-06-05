class UcrNumber < ApplicationRecord
  belongs_to :investigation
  validates :number, presence: true

end
