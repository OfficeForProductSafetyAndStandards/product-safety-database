class Test < ApplicationRecord
  include DateConcern
  include SanitizationHelper

  belongs_to :investigation
  belongs_to :product

  has_many_attached :documents

  date_attribute :date

  before_validation { trim_line_endings(:details) }
  validates :legislation, presence: { message: "Select the legislation that relates to this test" }
  validates :details, length: { maximum: 50_000 }

  def initialize(*args)
    raise "Cannot directly instantiate a Test record" if self.class == Test

    super
  end

  def pretty_name; end

  def requested?; end
end
