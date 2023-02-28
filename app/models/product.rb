class Product < ApplicationRecord
  include CountriesHelper
  include Documentable
  include Searchable
  include Retireable

  self.ignored_columns = %w[batch_number customs_code number_of_affected_units affected_units_status]

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

  index_name [ENV.fetch("OS_NAMESPACE", "default_namespace"), Rails.env, "products"].join("_")

  settings do
    mappings do
      indexes :name_for_sorting, type: :keyword
    end
  end

  def as_indexed_json(*)
    as_json(
      include: {
        investigations: {
          only: %i[category is_closed],
          methods: :owner_id
        }
      },
      methods: %i[tiebreaker_id name_for_sorting psd_ref retired?]
    )
  end

  # TODO: Remove this once attachments have been migrated
  has_many_attached :documents

  has_many :investigation_products, dependent: :destroy
  has_many :investigations, through: :investigation_products
  has_many :activities, through: :investigations

  has_many :corrective_actions, dependent: :destroy
  has_many :tests, dependent: :destroy
  has_many :test_results, class_name: "Test::Result", dependent: :destroy
  has_many :unexpected_events
  has_many :risk_assessed_products
  has_many :risk_assessments, through: :risk_assessed_products

  belongs_to :added_by_user, class_name: :User, optional: true
  belongs_to :owning_team, class_name: "Team", inverse_of: :owned_products, optional: true

  redacted_export_with :id, :added_by_user_id, :authenticity, :barcode,
                       :brand, :category, :country_of_origin, :created_at,
                       :description, :has_markings, :markings, :name,
                       :product_code, :retired_at, :subcategory, :updated_at,
                       :webpage, :when_placed_on_market, :owning_team_id

  scope :not_retired, -> { where(retired_at: nil) }

  def self.retire_stale_products!
    Product.not_retired.where("created_at < ?", 18.months.ago).select(&:stale?).each do |stale_product|
      stale_product.mark_as_retired!
      logger.debug "Marked product #{stale_product.id} as retired"
    end
  end

  def stale?
    return false if created_at > 18.months.ago
    return false if investigations.where(date_closed: nil).any?
    return false if investigations.where(date_closed: (18.months.ago..)).any?
    return true if investigations.none? && activities.where(type: ["AuditActivity::Product::Add", "AuditActivity::Product::Destroy"], created_at: (18.months.ago..)).none?

    false
  end

  def supporting_information
    tests + corrective_actions + unexpected_events + risk_assessments
  end

  def images
    document_uploads.select { |document_upload| document_upload.file_upload.content_type.starts_with?("image") }
  end

  def virus_free_images
    document_uploads.select do |document_upload|
      file_upload = document_upload.file_upload
      file_upload.content_type.starts_with?("image") && file_upload.metadata["safe"]
    end
  end

  # Expose document uploads similarly to other model attributes while managing them as an
  # array of IDs. This allows products to be versioned along with their associated document
  # uploads as they were at the time of the versioned product.
  def document_uploads
    DocumentUpload.where(id: document_upload_ids)
  end

  def name_for_sorting
    name
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
end
