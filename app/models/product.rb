class Product < ApplicationRecord
  include CountriesHelper
  include Documentable
  include Searchable
  include AttachmentConcern

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

  MARKINGS = %w[UKCA UKNI CE].freeze

  index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "products"].join("_")

  has_many_attached :documents

  has_many :investigation_products, dependent: :destroy
  has_many :investigations, through: :investigation_products

  has_many :corrective_actions, dependent: :destroy
  has_many :tests, dependent: :destroy

  has_one :source, as: :sourceable, dependent: :destroy
end
