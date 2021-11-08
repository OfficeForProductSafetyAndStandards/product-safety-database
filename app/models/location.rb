class Location < ApplicationRecord
  include CountriesHelper

  default_scope { order(created_at: :asc) }

  validates :name, presence: true

  belongs_to :business

  has_one :source, as: :sourceable, dependent: :destroy

  redacted_export_with :id, :address_line_1, :address_line_2, :business_id, :city, :country,
                       :county, :created_at, :name, :phone_number, :postal_code, :updated_at

  def summary
    [
      address_line_1,
      address_line_2,
      city,
      postal_code,
      country_from_code(country)
    ].reject(&:blank?).join(", ")
  end

  def short
    [
      county,
      country_from_code(country)
    ].reject(&:blank?).join(", ")
  end
end
