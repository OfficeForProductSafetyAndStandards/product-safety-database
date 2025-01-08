class SetBusinessTypeOnCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :type
  attribute :online_marketplace_id
  attribute :other_marketplace_name
  attribute :authorised_representative_choice

  BUSINESS_TYPES = %w[
    retailer online_seller online_marketplace manufacturer exporter importer fulfillment_house distributor authorised_representative responsible_person
  ].freeze

  validates_inclusion_of :type, in: BUSINESS_TYPES
  validates :online_marketplace_id, presence: true, if: -> { is_approved_online_marketplace? }
  validates :authorised_representative_choice, presence: true, if: -> { is_authorised_representative? }

  def set_params_on_session(session)
    session[:business_type] = type
    if is_approved_online_marketplace?
      session[:online_marketplace_id] = online_marketplace_id
    elsif is_other_online_marketplace?
      session[:other_marketplace_name] = other_marketplace_name
    elsif is_authorised_representative?
      session[:authorised_representative_choice] = authorised_representative_choice
    end
  end

  def clear_params_from_session(session)
    session.delete(:business_type)
    session.delete(:online_marketplace_id)
    session.delete(:other_marketplace_name)
    session.delete(:authorised_representative_choice)
  end

  def is_approved_online_marketplace?
    type == "online_marketplace" && other_marketplace_name.blank?
  end

  def approved_online_marketplace
    OnlineMarketplace.approved.find(online_marketplace_id)
  end

private

  def is_authorised_representative?
    type == "authorised_representative"
  end

  def is_other_online_marketplace?
    type == "online_marketplace" && other_marketplace_name.present?
  end
end
