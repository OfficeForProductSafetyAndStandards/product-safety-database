class Test < ApplicationRecord
  belongs_to :investigation
  belongs_to :product, optional: false

  has_one_attached :document

  redacted_export_with :id, :created_at, :date, :details, :failure_details, :investigation_id,
                       :legislation, :product_id, :result, :standards_product_was_tested_against,
                       :type, :updated_at

  def initialize(*args)
    raise "Cannot directly instantiate a Test record" if instance_of?(Test)

    super
  end

  def pretty_name; end

  def requested?; end
end
