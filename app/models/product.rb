class Product < ApplicationRecord
  include CountriesHelper
  include Documentable
  include Retireable

  self.ignored_columns = %w[batch_number customs_code number_of_affected_units affected_units_status ahoy_visit_id]

  has_paper_trail

  enum authenticity: {
    "counterfeit" => "counterfeit",
    "genuine" => "genuine",
    "unsure" => "unsure"
  }

  enum has_markings: {
    "markings_yes" => "markings_yes",
    "markings_no" => "markings_no",
    "markings_unknown" => "markings_unknown"
  }

  enum when_placed_on_market: {
    "before_2021" => "before_2021",
    "on_or_after_2021" => "on_or_after_2021",
    "unknown_date" => "unknown_date"
  }

  MARKINGS = %w[UKCA UKNI CE].freeze

  # TODO: Remove this once attachments have been migrated
  has_many_attached :documents

  has_many :investigation_products, dependent: :destroy
  has_many :investigations, through: :investigation_products
  has_many :activities, through: :investigations

  has_many :corrective_actions, through: :investigation_products, dependent: :destroy
  has_many :tests, through: :investigation_products, dependent: :destroy
  has_many :test_results, through: :investigation_products, class_name: "Test::Result", dependent: :destroy
  has_many :unexpected_events, through: :investigation_products
  has_many :risk_assessed_products, through: :investigation_products
  has_many :risk_assessments, through: :risk_assessed_products
  has_many :prism_associated_products
  has_many :prism_associated_investigation_products
  has_many :prism_risk_assessments_via_product, through: :prism_associated_products, class_name: "PrismRiskAssessment", source: :prism_risk_assessment
  has_many :prism_associated_investigations, through: :prism_associated_investigation_products
  has_many :prism_risk_assessments_via_investigations, through: :prism_associated_investigations, class_name: "PrismRiskAssessment", source: :prism_risk_assessment

  belongs_to :added_by_user, class_name: :User, optional: true
  belongs_to :owning_team, class_name: "Team", inverse_of: :owned_products, optional: true

  redacted_export_with :id, :added_by_user_id, :authenticity, :barcode,
                       :brand, :category, :country_of_origin, :created_at,
                       :description, :has_markings, :markings, :name,
                       :product_code, :retired_at, :subcategory, :updated_at,
                       :webpage, :when_placed_on_market, :owning_team_id

  scope :not_retired, -> { where(retired_at: nil) }

  def self.retire_stale_products!
    Product.not_retired.where("created_at < ?", 3.months.ago).select(&:stale?).each do |stale_product|
      stale_product.mark_as_retired!
      logger.debug "Marked product #{stale_product.id} as retired"
    end
  end

  def stale?
    return false if created_at > 3.months.ago
    return false if investigations.where(date_closed: nil).any?
    return false if investigations.where(date_closed: (3.months.ago..)).any?
    return true if investigations.none? && activities.where(type: ["AuditActivity::Product::Add", "AuditActivity::Product::Destroy"], created_at: (3.months.ago..)).none?

    false
  end

  def prism_risk_assessments
    prism_risk_assessments_via_product + prism_risk_assessments_via_investigations
  end

  def supporting_information
    tests + corrective_actions + unexpected_events + risk_assessments + prism_risk_assessments
  end

  def virus_free_images
    image_uploads.select { |image_upload| image_upload&.file_upload&.metadata&.dig("safe") }
  end

  # Expose document uploads similarly to other model attributes while managing them as an
  # array of IDs. This allows products to be versioned along with their associated document
  # uploads as they were at the time of the versioned product.
  def document_uploads
    DocumentUpload.where(id: document_upload_ids)
  end

  # Expose image uploads similarly to other model attributes while managing them as an
  # array of IDs. This allows products to be versioned along with their associated image
  # uploads as they were at the time of the versioned product.
  def image_uploads
    ImageUpload.where(id: image_upload_ids)
  end

  def psd_ref(timestamp: nil, investigation_was_closed: false)
    ref = "psd-#{id}"

    # Timestamp to append is not necessarily the same as when the version was created.
    # Passing investigation_was_closed: true allows us add a timestamp to the psd_ref even if it is the live product version. Useful to
    # illustrate to users why they can't edit/remove a product that was attached when the case was closed even if it is the live version.
    if (version.present? && timestamp.present?) || investigation_was_closed
      ref << "_#{timestamp}"
    end

    ref
  end

  def unique_investigation_products
    investigation_products.uniq(&:investigation_id)
  end

  def get_notification_images
    investigations.flat_map(&:image_uploads)
  end

  def get_investigations_count_for_display
    investigations.where(type: ["Investigation::Allegation", "Investigation::Project", "Investigation::Enquiry"])
                  .or(investigations.where(type: "Investigation::Notification", state: "submitted")).count
  end
end
