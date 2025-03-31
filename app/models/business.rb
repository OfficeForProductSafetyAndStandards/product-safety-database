class Business < ApplicationRecord
  include BusinessesHelper
  include Documentable
  include AttachmentConcern

  BUSINESS_TYPES = %w[
    retailer online_seller online_marketplace manufacturer exporter importer fulfillment_house distributor authorised_representative responsible_person
  ].freeze

  before_validation :trim_spaces
  validates :trading_name, presence: true

  has_many_attached :documents

  has_many :investigation_businesses, dependent: :destroy
  has_many :investigations, through: :investigation_businesses

  has_many :investigation_products, through: :investigations
  has_many :products, through: :investigation_products

  has_many :locations, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :corrective_actions, dependent: :destroy
  has_many :risk_assessments, dependent: :destroy, foreign_key: :assessed_by_business_id

  belongs_to :online_marketplace, optional: true
  belongs_to :added_by_user, class_name: :User, optional: true

  scope :without_online_marketplaces, -> { where(online_marketplace_id: nil) }

  accepts_nested_attributes_for :locations, reject_if: :all_blank
  accepts_nested_attributes_for :contacts, reject_if: :all_blank

  redacted_export_with :id, :added_by_user_id, :company_number, :created_at,
                       :legal_name, :trading_name, :updated_at

  def submitted_investigation_businesses
    investigation_businesses.reject do |ib|
      ib.investigation.is_a?(Investigation::Notification) && ib.investigation.state == "draft"
    end
  end

  def submitted_notifications_count
    submitted_investigation_businesses.count
  end

  def supporting_information
    corrective_actions + risk_assessments
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

  def trim_spaces
    self.legal_name = legal_name&.squish
    self.trading_name = trading_name&.squish
    self.company_number = company_number&.squish
  end
end
