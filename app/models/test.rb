class Test < ApplicationRecord
  belongs_to :investigation
  belongs_to :product

  has_one_attached :document

  def initialize(*args)
    raise "Cannot directly instantiate a Test record" if self.class == Test

    super
  end

  def pretty_name; end

  def requested?; end
end
