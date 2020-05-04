module SanitizationHelper
  # Browsers treat end of line as one character when checking input length, but send it as \r\n, 2 characters
  # To keep max length consistent we need to reverse that
  def trim_line_endings(*keys)
    keys.each do |key|
      send(key).gsub!("\r\n", "\n") if send(key)
    end
  end
end
