class SetBusinessTypeOnCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :type
  attribute :online_marketplace_id

  BUSINESS_TYPES = %w[
    retailer online_marketplace manufacturer exporter importer fulfillment_house distributor
  ].freeze

  validates_inclusion_of :type, in: BUSINESS_TYPES

  def set_params_on_session(session)
    session[:business_type] = type
    session[:online_marketplace_id] = online_marketplace_id if is_online_marketplace?
  end

private

  def is_online_marketplace?
    type == "online_marketplace"
  end
end
