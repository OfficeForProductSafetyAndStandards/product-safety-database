class FindProductDuplicates
  include Interactor

  delegate :barcode, to: :context

  def call
    context.fail!(error: "No barcode supplied") if barcode.blank?

    context.duplicates = find_duplicates
  end

private

  def cleaned_barcode
    barcode.gsub(/[^0-9]/, "")
  end

  def find_duplicates
    Product.where(barcode: cleaned_barcode)
  end
end
