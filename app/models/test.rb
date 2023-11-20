class Test < ApplicationRecord
  belongs_to :investigation
  belongs_to :investigation_product, optional: false
  self.ignored_columns = %w[product_id]

  has_one_attached :document

  redacted_export_with :id, :created_at, :date, :details, :failure_details, :investigation_id,
                       :legislation, :investigation_product_id, :result, :standards_product_was_tested_against,
                       :type, :updated_at, :tso_certificate_issue_date, :tso_certificate_reference_number

  def initialize(*args)
    raise "Cannot directly instantiate a Test record" if instance_of?(Test)

    super
  end

  def pretty_name; end

  def requested?; end
end
