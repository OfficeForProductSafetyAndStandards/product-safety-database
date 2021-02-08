class UnexpectedEvent < ApplicationRecord
  belongs_to :investigation
  belongs_to :product

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
