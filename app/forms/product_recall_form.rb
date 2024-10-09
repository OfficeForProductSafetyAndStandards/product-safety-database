class ProductRecallForm
  include Rails.application.routes.url_helpers
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :step, :integer, default: 1
  attribute :type, :string, default: "product_recall"
  attribute :product_image_ids, default: []
  attribute :pdf_title, :string
  attribute :alert_number, :string
  attribute :product_type, :string
  attribute :subcategory, :string
  attribute :product_identifiers, :string
  attribute :product_description, :string
  attribute :country_of_origin, :string
  attribute :counterfeit, :string
  attribute :risk_type, :string
  attribute :risk_level, :string
  attribute :risk_description, :string
  attribute :corrective_actions, :string
  attribute :other_corrective_action, :string
  attribute :online_marketplace, :boolean
  attribute :is_listing_removed, :boolean
  attribute :online_marketplace_id, :string
  attribute :other_marketplace_name, :string
  attribute :notified_by, :string
  attribute :notification_image_ids, default: []

  def advance!(num = 1)
    self.step += num
  end

  def back!(num = 1)
    self.step -= num
  end

  def first_step?
    self.step == 1
  end

  def last_step?
    self.step == 3
  end

  def go_back
    attributes.merge(back: true)
  end

  def go_forward
    attributes.merge(forward: true)
  end
end
