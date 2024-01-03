class DeleteNotificationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :notification

  validates :notification, presence: true
  validate :notification_has_no_products

  def notification_has_no_products
    errors.add(:has_products, "Cannot delete a notification with products") unless notification && notification.products.none?
  end
end
