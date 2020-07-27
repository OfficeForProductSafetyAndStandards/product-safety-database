class CorrectiveAction < ApplicationRecord
  DURATION_TYPES = %w[permanent temporary unknown].freeze
  MEASURE_TYPES = %w[mandatory voluntary].freeze

  include DateConcern
  include SanitizationHelper

  attribute :related_file, :boolean
  include CorrectiveActionValidation

  date_attribute :date_decided

  belongs_to :investigation
  belongs_to :business, optional: true
  belongs_to :product

  has_many_attached :documents

  after_create :create_audit_activity

  before_validation { trim_line_endings(:summary, :details) }

private

  def create_audit_activity
    AuditActivity::CorrectiveAction::Add.from(self)
  end
end
