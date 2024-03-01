class AddBusinessRolesForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :roles, array: true
  attribute :online_marketplace_id
  attribute :new_online_marketplace_name
  attribute :authorised_representative_choice
  attribute :business_id

  validate :online_marketplace_or_other
  validate :online_marketplace_provided
  validate :only_allowed_business_types
  validates :authorised_representative_choice, inclusion: { in: %w[uk_authorised_representative eu_authorised_representative] }, if: -> { roles.include?("authorised_representative") }

private

  def online_marketplace_or_other
    errors.add(:roles, "Choose either online marketplace or another role") if roles.include?("online_marketplace") && roles.compact_blank.count > 1
  end

  def only_allowed_business_types
    errors.add(:roles, "Please select at least one role") unless (roles.compact_blank! - Business::BUSINESS_TYPES).empty?
  end

  def online_marketplace_provided
    return true unless roles.include?("online_marketplace")

    errors.add(:online_marketplace_id, "Please select an online marketplace") unless online_marketplace_id.present? || new_online_marketplace_name.present?
    errors.add(:online_marketplace_id, "Please select an existing online marketplace or a new online marketplace") if online_marketplace_id.present? && new_online_marketplace_name.present?
  end
end
