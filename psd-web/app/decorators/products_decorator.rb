class ProductsDecorator < Draper::CollectionDecorator
  PRODUCT_IMAGE_DISPLAY_LIMIT = 6
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  def image_list
    h.tag.ul(class: "govuk-list") do
      h.render object
    end
  end
end
