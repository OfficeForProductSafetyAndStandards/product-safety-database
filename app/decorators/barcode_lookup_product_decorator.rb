class BarcodeLookupProductDecorator < ApplicationDecorator
  include FormattedDescription
  delegate_all

  def name_with_brand
    [brand, title].compact.join(" - ")
  end

  def has_images?
    images.present?
  end

  def image_urls
    JSON.parse(images)
  end

  def model
    object.model || object.mpn
  end

end