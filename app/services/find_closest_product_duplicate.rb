class FindClosestProductDuplicate
  include Interactor

  delegate :barcode, to: :context

  def call
    context.fail!(error: "No barcode supplied") if barcode.blank?

    context.duplicate = find_duplicate
  end

private

  def cleaned_barcode
    barcode.gsub(/[^0-9]/, "")
  end

  def find_duplicate
    products = Product.not_retired.where(barcode: cleaned_barcode).includes(:investigations)
    return products.first if products.count == 1

    matching_products_ordered_by_case_count = products.select { |product| product.investigations.count.positive? }
    if matching_products_ordered_by_case_count.present?
      return matching_products_ordered_by_case_count.first
    end

    if products.where(authenticity: "genuine").count.positive?
      return products.where(authenticity: "genuine").first
    end

    products.order(created_at: :asc).first
  end
end
