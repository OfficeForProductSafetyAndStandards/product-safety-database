module SanitizationHelper
  # Browsers treat end of line as one character when checking input length, but send it as \r\n, 2 characters
  # To keep max length consistent we need to reverse that
  def trim_line_endings(*keys)
    keys.each do |key|
      public_send(key).gsub!("\r\n", "\n") if send(key)
    end
  end

  def nilify_blanks(*keys)
    keys.each do |key|
      public_send("#{key}=", attribute(key).presence)
    end
  end

  def trim_whitespace(*keys)
    keys.each do |key|
      public_send("#{key}=", attribute(key)&.strip)
    end
  end

  def convert_gtin_to_13_digits(*keys)
    gtin = nil
    keys.each do |key|
      begin
        gtin = Barkick::GTIN.new(attribute(key)&.strip)
      # 8 digit codes raise an ArgumentError, as a type (UPC-E or EAN-8) needs
      # to be specified in order to convert the code to a valid GTIN
      rescue ArgumentError
        gtin = Barkick::GTIN.new(attribute(key)&.strip, type: :upc_e)
        gtin = Barkick::GTIN.new(attribute(key)&.strip, type: :ean8) unless gtin.valid?
      end

      code = gtin.valid? ? gtin.gtin13 : nil
      write_attribute(key, code)
    end
  end
end
