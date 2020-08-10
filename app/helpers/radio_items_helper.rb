module RadioItemsHelper
  def radio_items_from_hash(hash)
    hash.collect do |key, value|
      { value: key, text: value }
    end
  end
end
