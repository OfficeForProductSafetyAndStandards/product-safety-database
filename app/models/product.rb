class Product < ApplicationRecord
  include CountriesHelper
  include Documentable
  include Searchable
  include AttachmentConcern

  after_commit do
    investigations.import
  end

  enum authenticity: {
    "counterfeit" => "counterfeit",
    "genuine" => "genuine",
    "unsure" => "unsure"
  }

  enum affected_units_status: {
    "exact" => "exact",
    "approx" => "approx",
    "unknown" => "unknown",
    "not_relevant" => "not_relevant"
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

  index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "products"].join("_")

  has_many_attached :documents

  has_many :investigation_products, dependent: :destroy
  has_many :investigations, through: :investigation_products

  has_many :corrective_actions, dependent: :destroy
  has_many :tests, dependent: :destroy
  has_many :unexpected_events
  has_many :risk_assessed_products
  has_many :risk_assessments, through: :risk_assessed_products

  has_one :source, as: :sourceable, dependent: :destroy

  def supporting_information
    tests + corrective_actions + unexpected_events + risk_assessments
  end
end
