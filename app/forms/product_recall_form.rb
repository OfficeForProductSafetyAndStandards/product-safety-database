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
  attribute :online_marketplace_id, :string
  attribute :other_marketplace_name, :string
  attribute :notified_by, :string

  def product_images(product)
    product.virus_free_images.map do |img|
      {
        text: img.file_upload.filename,
        value: img.id,
        disable_ghost: true,
        checked: product_image_ids.to_a.include?(img.id),
        html: "<div class='opss-checkboxes-thumbnails_img' style='background-image: url(#{rails_storage_proxy_path(img.file_upload, only_path: true)})'></div>".html_safe
      }
    end
  end

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
