class Business < ApplicationRecord
  include BusinessesHelper
  include Searchable
  include Documentable
  include AttachmentConcern

  index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "business"].join("_")

  settings do
    mappings do
      indexes :company_number, type: :keyword
      indexes :company_type_code, type: :keyword, fields: { sort: { type: "keyword" } }
      indexes :company_status_code, type: :keyword, fields: { sort: { type: "keyword" } }
    end
  end

  validates :trading_name, presence: true

  has_many_attached :documents

  has_many :investigation_businesses, dependent: :destroy
  has_many :investigations, through: :investigation_businesses

  has_many :locations, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :corrective_actions, dependent: :destroy

  accepts_nested_attributes_for :locations, reject_if: :all_blank
  accepts_nested_attributes_for :contacts, reject_if: :all_blank

  has_one :source, as: :sourceable, dependent: :destroy

  delegate :address_line_1, :address_line_2, :city, :country, :county, :phone_number, :postal_code, to: :primary_location, prefix: true, allow_nil: true
  delegate :email, :job_title, :name, :phone_number, to: :primary_contact, prefix: true, allow_nil: true

  def self.attributes_for_export
    attribute_names.dup.concat(%w[types case_ids primary_location_address_line_1 primary_location_address_line_2 primary_location_city primary_location_country primary_location_county primary_location_postal_code primary_location_phone_number primary_contact_email primary_contact_name primary_contact_phone_number primary_contact_job_title]).sort.freeze
  end

  def types
    investigation_businesses.map(&:relationship)
  end

  def case_ids
    investigations.map(&:pretty_id)
  end

  def primary_location
    locations.first
  end

  def primary_contact
    contacts.first
  end

  def pretty_description
    "Business: #{trading_name}"
  end

  def contacts_have_errors?
    contacts&.any? { |contact| contact.errors.any? } || false
  end

  def locations_have_errors?
    locations&.any? { |location| location.errors.any? } || false
  end
end
