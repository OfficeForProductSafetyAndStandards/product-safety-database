module Prism
  class HarmScenarioStepEvidence < ApplicationRecord
    # This intermediate model is required between a harm scenario step
    # and its associated evidence because the existing PSD Active Storage
    # installation uses integer primary keys, whereas all PRISM models use
    # UUIDs. This model is configured to use integer primary keys for
    # compatibility with Active Storage.
    belongs_to :harm_scenario_step
    has_one_attached :evidence_file

    ALLOWED_CONTENT_TYPES = %w[
      application/pdf
      image/jpeg
      image/gif
      image/png
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ].freeze

    validates :evidence_file, attached: true, size: { between: 1.byte..30.megabytes }, content_type: { in: ALLOWED_CONTENT_TYPES }
  end
end
