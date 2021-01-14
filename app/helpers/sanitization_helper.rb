module SanitizationHelper
  # Browsers treat end of line as one character when checking input length, but send it as \r\n, 2 characters
  # To keep max length consistent we need to reverse that
  def trim_line_endings(*keys)
    keys.each do |key|
      public_send("#{key}=", attributes[key.to_s].gsub("\r\n", "\n")) if attributes[key.to_s]
    end
  end

  def nilify_blanks(*keys)
    keys.each do |key|
      public_send("#{key}=", attributes[key.to_s].presence)
    end
  end

  def trim_whitespace(*keys)
    keys.each do |key|
      public_send("#{key}=", attributes[key.to_s]&.strip)
    end
  end
end
