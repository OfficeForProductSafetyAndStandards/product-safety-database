class UnexpectedEvent < ApplicationRecord
  self.ignored_columns = %w[product_id]

  belongs_to :investigation
  belongs_to :investigation_product

  redacted_export_with :id, :additional_info, :created_at, :date, :investigation_id,
                       :is_date_known, :investigation_product_id, :severity, :severity_other, :type,
                       :updated_at, :usage

  enum usage: {
    "during_normal_use" => "during_normal_use",
    "during_misuse" => "during_misuse",
    "with_adult_supervision" => "with_adult_supervision",
    "without_adult_supervision" => "without_adult_supervision",
    "unknown_usage" => "unknown_usage"
  }

  enum severity: {
    "serious" => "serious",
    "high" => "high",
    "medium" => "medium",
    "low" => "low",
    "unknown_severity" => "unknown_severity",
    "other" => "other"
  }
end
