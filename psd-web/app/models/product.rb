class Product < ApplicationRecord
  include CountriesHelper
  include Documentable
  include Searchable
  include AttachmentConcern
  include SanitizationHelper

  before_validation { trim_line_endings(:description) }
  validates :name, presence: true
  validates :product_type, presence: true
  validates :category, presence: true
  validates :description, length: { maximum: 10000 }

  index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "products"].join("_")

  has_many_attached :documents

  has_many :investigation_products, dependent: :destroy
  has_many :investigations, through: :investigation_products

  has_many :corrective_actions, dependent: :destroy
  has_many :tests, dependent: :destroy

  has_one :source, as: :sourceable, dependent: :destroy

  def pretty_description
    "Product: #{name}"
  end
end
