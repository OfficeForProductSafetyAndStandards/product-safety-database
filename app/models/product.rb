class Product < ApplicationRecord
  include CountriesHelper
  include Documentable
  include Searchable
  include AttachmentConcern
  include SanitizationHelper

  enum authenticity: {
    counterfeit: I18n.t(:counterfeit, scope: %i[product attributes authenticities]),
    genuine: I18n.t(:genuine, scope: %i[product attributes authenticities]),
    unsure: I18n.t(:unsure, scope: %i[product attributes authenticities]),
    missing: I18n.t(:not_provided, scope: %i[product attributes authenticities])
  }



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
