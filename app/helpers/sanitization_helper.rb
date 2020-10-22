module SanitizationHelper
  # Browsers treat end of line as one character when checking input length, but send it as \r\n, 2 characters
  # To keep max length consistent we need to reverse that
  def trim_line_endings(*keys)
    keys.each do |key|
      send(key).gsub!("\r\n", "\n") if send(key)
    end
  end

  def nilify_blanks(*keys)
    keys.each do |key|
      write_attribute(key, read_attribute(key).presence)
    end
  end

  def convert_gtin_to_13_digits(*keys)
    keys.each do |key|
      gtin = Barkick::GTIN.new(read_attribute(key)&.strip)
      write_attribute(key, gtin.gtin13) if gtin.valid?
    # 8 digit codes raise an ArgumentError, as a type (UPC-E or EAN-8) needs
    # to be specified in order to convert the code to a valid GTIN
    rescue ArgumentError
      next
    end
  end
end
