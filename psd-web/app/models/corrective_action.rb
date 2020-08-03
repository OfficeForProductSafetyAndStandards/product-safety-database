class CorrectiveAction < ApplicationRecord
  include DateConcern
  include SanitizationHelper

  DURATION_TYPES = %w[permanent temporary unknown].freeze
  MEASURE_TYPES = %w[mandatory voluntary].freeze
  attribute :related_file, :boolean

  date_attribute :date_decided

  belongs_to :investigation
  belongs_to :business, optional: true
  belongs_to :product

  has_many_attached :documents

  after_create :create_audit_activity

  before_validation { trim_line_endings(:summary, :details) }

  attribute :related_file, :boolean

  validates :related_file, inclusion: { in: [true, false], message: "Select whether you want to upload a related file" }
  validate :related_file_attachment_validation
  validate :date_decided_cannot_be_in_the_future

  validates :summary, presence: { message: "Enter a summary of the corrective action" }
  validates :legislation, presence: { message: "Select the legislation relevant to the corrective action" }
  validates :summary, presence: { message: "Enter a summary of the corrective action" }
  validates :legislation, presence: { message: "Select the legislation relevant to the corrective action" }

  validates :measure_type, presence: true
  validates :measure_type, inclusion: { in: CorrectiveAction::MEASURE_TYPES }, if: -> { measure_type.present? }
  validates :duration, presence: true
  validates :duration, inclusion: { in: CorrectiveAction::DURATION_TYPES }, if: -> { duration.present? }
  validates :geographic_scope, presence: true
  validates :geographic_scope, inclusion: { in: Rails.application.config.corrective_action_constants["geographic_scope"] }, if: -> { geographic_scope.present? }
  validates :details, length: { maximum: 50_000 }

private

  def date_decided_cannot_be_in_the_future
    if date_decided.present? && date_decided > Time.zone.today
      errors.add(:date_decided, "The date of corrective action decision can not be in the future")
    end
  end

  def create_audit_activity
    AuditActivity::CorrectiveAction::Add.from(self)
  end

  def related_file_attachment_validation
    if related_file && documents.attachments.empty?
      errors.add(:base, :file_missing, message: "Provide a related file or select no")
    end
  end
end
