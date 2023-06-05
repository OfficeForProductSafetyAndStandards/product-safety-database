class UcrNumber < ApplicationRecord
  belongs_to :investigation_product
  validates :number, presence: true

end
